import Foundation

enum ZIPArchiveWriterError: Error {
    case symbolicLinkUnsupported, emptySelection, invalidSource, duplicateEntry, archiveTooLarge, writeFailed
}
enum ZIPArchiveExtractorError: Error {
    case symbolicLinkUnsupported, invalidArchive, insufficientSpace, extractionFailed
}
struct ZIPArchiveWriteResult { let entryCount: Int; let sourceBytes: Int64 }
struct ZIPArchiveExtractionResult: Equatable {
    let extractedURL: URL
    let files: [URL]
    let entryCount: Int
    let extractedBytes: Int64
}

private enum Z {
    static let local: UInt32 = 0x04034b50
    static let central: UInt32 = 0x02014b50
    static let end: UInt32 = 0x06054b50
    static let maxSize: Int64 = 4 * 1024 * 1024 * 1024
    static func d16(_ n: UInt16) -> Data { var x=n.littleEndian; return Data(bytes:&x,count:2) }
    static func d32(_ n: UInt32) -> Data { var x=n.littleEndian; return Data(bytes:&x,count:4) }
    static func u16(_ d: Data,_ i:Int)->UInt16? { guard i>=0 && i+2<=d.count else{return nil}; return UInt16(d[i]) | UInt16(d[i+1])<<8 }
    static func u32(_ d: Data,_ i:Int)->UInt32? { guard i>=0 && i+4<=d.count else{return nil}; return UInt32(d[i]) | UInt32(d[i+1])<<8 | UInt32(d[i+2])<<16 | UInt32(d[i+3])<<24 }
    static func safe(_ name:String)->String? {
        var s=name.replacingOccurrences(of:"\\",with:"/")
        while s.hasPrefix("./"){s.removeFirst(2)}
        while s.hasPrefix("/"){s.removeFirst()}
        let c=s.split(separator:"/",omittingEmptySubsequences:true)
        guard !c.isEmpty,!c.contains("..") else{return nil}
        return c.map(String.init).joined(separator:"/")
    }
    static func crc(_ url:URL)throws->(UInt32,Int64){
        let h=try FileHandle(forReadingFrom:url); defer{try? h.close()}
        var c:UInt32=0xffff_ffff,n:Int64=0
        while let d=try h.read(upToCount:1_048_576),!d.isEmpty { n += Int64(d.count); for b in d { c ^= UInt32(b); for _ in 0..<8 { c=(c>>1)^((c&1)==1 ? 0xedb8_8320:0) } } }
        return (c ^ 0xffff_ffff,n)
    }
}

enum ZIPArchiveWriter {
    static func write(items sources:[URL], to dest:URL, fileManager fm: FileManager = .default) throws -> ZIPArchiveWriteResult {
        guard !sources.isEmpty else{throw ZIPArchiveWriterError.emptySelection}
        guard !fm.fileExists(atPath:dest.path) else{throw ZIPArchiveWriterError.duplicateEntry}
        struct E {let name:String;let url:URL?;let dir:Bool;let crc:UInt32;let size:UInt32;let offset:UInt32}
        var pending:[(String,URL?,Bool)]=[], seen=Set<String>()
        for src in sources {
            let rv=try? src.resourceValues(forKeys:[.isDirectoryKey,.isSymbolicLinkKey])
            guard fm.fileExists(atPath:src.path) else{throw ZIPArchiveWriterError.invalidSource}
            guard rv?.isSymbolicLink != true else{throw ZIPArchiveWriterError.symbolicLinkUnsupported}
            guard let base=Z.safe(src.lastPathComponent) else{throw ZIPArchiveWriterError.invalidSource}
            let dir=rv?.isDirectory == true, name=base+(dir ? "/":"")
            guard seen.insert(name).inserted else{throw ZIPArchiveWriterError.duplicateEntry}; pending.append((name,src,dir))
            if dir,let en=fm.enumerator(at:src,includingPropertiesForKeys:[.isDirectoryKey,.isSymbolicLinkKey],options:[]) {
                for case let child as URL in en {
                    let crv=try? child.resourceValues(forKeys:[.isDirectoryKey,.isSymbolicLinkKey])
                    guard crv?.isSymbolicLink != true else{throw ZIPArchiveWriterError.symbolicLinkUnsupported}
                    let root=src.standardizedFileURL.path.hasSuffix("/") ? src.standardizedFileURL.path : src.standardizedFileURL.path+"/"
                    guard let rel=Z.safe(String(child.standardizedFileURL.path.dropFirst(root.count))) else{throw ZIPArchiveWriterError.invalidSource}
                    let cn=name+rel+(crv?.isDirectory == true ? "/":"")
                    guard seen.insert(cn).inserted else{throw ZIPArchiveWriterError.duplicateEntry}; pending.append((cn,child,crv?.isDirectory == true))
                }
            }
        }
        do {
            try fm.createDirectory(at:dest.deletingLastPathComponent(),withIntermediateDirectories:true)
            fm.createFile(atPath:dest.path,contents:nil); let h=try FileHandle(forWritingTo:dest); defer{try?h.close()}
            var es:[E]=[], total:Int64=0
            for (name,url,dir) in pending {
                let nb=Data(name.utf8); guard nb.count<=Int(UInt16.max) else{throw ZIPArchiveWriterError.invalidSource}
                let off=try h.offset(); guard off<=UInt64(UInt32.max) else{throw ZIPArchiveWriterError.archiveTooLarge}
                let pair: (UInt32,Int64) = dir ? (0,0) : try Z.crc(url!)
                total += pair.1; guard pair.1<=Int64(UInt32.max),total<=Z.maxSize else{throw ZIPArchiveWriterError.archiveTooLarge}
                let sz=UInt32(pair.1); var x=Data(); x.append(Z.d32(Z.local)); x.append(Z.d16(20)); x.append(Z.d16(0x800)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d32(pair.0)); x.append(Z.d32(sz)); x.append(Z.d32(sz)); x.append(Z.d16(UInt16(nb.count))); x.append(Z.d16(0)); x.append(nb); try h.write(contentsOf:x)
                if !dir { let r=try FileHandle(forReadingFrom:url!); defer{try?r.close()}; while let d=try r.read(upToCount:1_048_576),!d.isEmpty{try h.write(contentsOf:d)} }
                es.append(E(name:name,url:url,dir:dir,crc:pair.0,size:sz,offset:UInt32(off)))
            }
            let co=try h.offset(); guard co<=UInt64(UInt32.max) else{throw ZIPArchiveWriterError.archiveTooLarge}
            for e in es { let nb=Data(e.name.utf8); var x=Data(); x.append(Z.d32(Z.central)); x.append(Z.d16(20)); x.append(Z.d16(20)); x.append(Z.d16(0x800)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d32(e.crc)); x.append(Z.d32(e.size)); x.append(Z.d32(e.size)); x.append(Z.d16(UInt16(nb.count))); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d16(0)); x.append(Z.d32(e.dir ? 0x10:0)); x.append(Z.d32(e.offset)); x.append(nb); try h.write(contentsOf:x) }
            let ce=try h.offset(), cs=ce-co; guard es.count<=Int(UInt16.max),cs<=UInt64(UInt32.max) else{throw ZIPArchiveWriterError.archiveTooLarge}
            var end=Data(); end.append(Z.d32(Z.end)); end.append(Z.d16(0)); end.append(Z.d16(0)); end.append(Z.d16(UInt16(es.count))); end.append(Z.d16(UInt16(es.count))); end.append(Z.d32(UInt32(cs))); end.append(Z.d32(UInt32(co))); end.append(Z.d16(0)); try h.write(contentsOf:end)
            return ZIPArchiveWriteResult(entryCount:es.count,sourceBytes:total)
        } catch let e as ZIPArchiveWriterError {try? fm.removeItem(at:dest);throw e} catch {try? fm.removeItem(at:dest);throw ZIPArchiveWriterError.writeFailed}
    }
}

enum ZIPArchiveExtractor {
    static func extract(archiveURL:URL,into dest:URL,fileManager fm: FileManager = .default) throws -> ZIPArchiveExtractionResult {
        guard fm.fileExists(atPath:archiveURL.path) else{throw ZIPArchiveExtractorError.invalidArchive}
        let d:Data; do{d=try Data(contentsOf:archiveURL,options:.mappedIfSafe)}catch{throw ZIPArchiveExtractorError.invalidArchive}
        guard Int64(d.count)<=Z.maxSize else{throw ZIPArchiveExtractorError.insufficientSpace}
        try fm.createDirectory(at:dest,withIntermediateDirectories:true)
        var i=0, count=0, total:Int64=0, files:[URL]=[], seen=Set<String>()
        while i+4<=d.count {
            guard let sig=Z.u32(d,i) else{throw ZIPArchiveExtractorError.invalidArchive}
            if sig==Z.central || sig==Z.end {break}; guard sig==Z.local else{throw ZIPArchiveExtractorError.invalidArchive}
            guard let flags=Z.u16(d,i+6),let method=Z.u16(d,i+8),let csize=Z.u32(d,i+18),let usize=Z.u32(d,i+22),let nl=Z.u16(d,i+26),let xl=Z.u16(d,i+28),method==0,flags&1==0,flags&8==0 else{throw ZIPArchiveExtractorError.invalidArchive}
            let ns=i+30, ds=ns+Int(nl)+Int(xl), de=ds+Int(csize); guard de>=ds,de<=d.count else{throw ZIPArchiveExtractorError.invalidArchive}
            guard let raw=String(data:d[ns..<ns+Int(nl)],encoding:.utf8),let name=Z.safe(raw),seen.insert(name).inserted else{throw ZIPArchiveExtractorError.invalidArchive}
            let dir=name.hasSuffix("/"), rel=dir ? String(name.dropLast()):name, target=dest.appendingPathComponent(rel,isDirectory:dir).standardizedFileURL, base=dest.standardizedFileURL.path
            guard target.path==base || target.path.hasPrefix(base+(base.hasSuffix("/") ? "":"/")) else{throw ZIPArchiveExtractorError.invalidArchive}
            if dir {try fm.createDirectory(at:target,withIntermediateDirectories:true)} else { if fm.fileExists(atPath:target.path){throw ZIPArchiveExtractorError.extractionFailed}; try fm.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true); let bytes=Data(d[ds..<de]); guard bytes.count==Int(usize) else{throw ZIPArchiveExtractorError.invalidArchive}; total += Int64(bytes.count); guard total<=Z.maxSize else{throw ZIPArchiveExtractorError.insufficientSpace}; do{try bytes.write(to:target,options:.atomic)}catch{throw ZIPArchiveExtractorError.extractionFailed}; files.append(target) }
            count += 1; i=de
        }
        guard count>0 else{throw ZIPArchiveExtractorError.invalidArchive}
        return ZIPArchiveExtractionResult(extractedURL:dest,files:files,entryCount:count,extractedBytes:total)
    }
}
