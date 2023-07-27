import os
import sys


for a in sys.argv:
    if a.startswith("--dir="):
        dst = a[6:]
    if a.startswith("--mbr="):
        with open(a[6:], "rb") as f:
            mbr = f.read()
    if a.startswith("--prt="):
        with open(a[6:], "rb") as f:
            prt = f.read()
    if a.startswith("--vbr="):
        with open(a[6:], "rb") as f:
            vbr = f.read()
    if a.startswith("--max="):
        max_size = eval(a[6:])
    if a.startswith("--device="):
        device = a[9:]
    if a.startswith("--fs="):
        fs = a[5:]

if "--no-partitions" not in sys.argv or "--make-partitions" in sys.argv:
    os.system("rm image.raw 2>/dev/null")
    os.system("dd if=/dev/zero of=image.raw bs=1M count=64")
    os.system("sudo mkfs.fat -F 32 image.raw")
    if not os.path.exists("/mnt/vfat32"):
        os.system("sudo mkdir /mnt/vfat32")
    os.system("sudo mount -o loop image.raw /mnt/vfat32")
    os.system(f"sudo cp -r {os.path.abspath(dst).removesuffix('/')}/* /mnt/vfat32")
    os.system("sudo umount /mnt/vfat32")
    os.system("chown talisman image.raw")

    with open("image.raw", "rb") as f:
        image = f.read()

    del f

    prtofs = 0xC00

    # phase 1 - fix partition mbr
    image = image[:prtofs] + prt[:11] + image[prtofs+11:]  # fix version specification
    image = image[:prtofs+46] + prt[46:] + image[prtofs+512:]  # add bootloader

    # phase 2 - fix vbr
    image = image[:512] + vbr + image[1024:]

    # phase 3 - fix image mbr
    #image = mbr[:446] + image[446:]
    image = mbr[:512] + image[512:]

    # DANGER
    #image = image[0xc00:]

    with open("image.raw", "wb") as f:
        f.write(image)
else:
    if fs == "dictfs":
        # dictfs is pretty simple:
        # it's just dict where keys are paths
        # and values are CHS addresses
        files = []
        dirs = []
        for d in os.walk(dst):
            dirs.append(d[0])
            for f in d[2]:
                files.append(d[0]+"/"+f)
        
        for i, f in enumerate(files):
            #           path size                addr sectors
            files[i] = [f,   os.path.getsize(f), -1,  os.path.getsize(f)//512+(1 if os.path.getsize(f) % 512 else 0)]
            print(files[i])
        
        data = b""

        for n, f in enumerate(files):
            with open(f[0], "rb") as f:
                raw = f.read()
            print("addr:", len(data)//512+4)
            files[n][2] = len(data)//512+4
            data += raw
            data += b"\x00"*(512 - (len(data) % 512))

        fsinfo = b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00HexOS Disk\x00"
        fsinfo += b"\x00"*(512 - (len(fsinfo) % 512))

        for i in files:
            fsinfo += b'\x80'+i[1].to_bytes(4, "little")+i[2].to_bytes(4, "little")+\
                i[3].to_bytes(1, "little")+i[0].removeprefix("dst/hexos").encode("ascii")+b"\x00"

        for i in dirs:
            fsinfo += b'\x90'+i.removeprefix("dst/hexos").encode("ascii")+b"\x00"

        fsinfo += b"\x00"*(512-(len(fsinfo) % 512))

        infosize = len(fsinfo)//512

        fsinfo = b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00HexOS Disk\x00"
        fsinfo += b"\x00"*(512 - (len(fsinfo) % 512))

        for i in files:
            print(i)
            fsinfo += b'\x80'+i[2].to_bytes(4, "little")+(i[1]+infosize).to_bytes(4, "little")+\
                i[3].to_bytes(1, "little")+i[0].removeprefix("dst/hexos").encode("ascii")+b"\x00"

        for i in dirs:
            fsinfo += b'\x90'+i.removeprefix("dst/hexos").encode("ascii")+b"\x00"

        fsinfo += b"\x00"*(512-(len(fsinfo) % 512))

        image = mbr+fsinfo+data+b"\x00"*(max_size-len(mbr+fsinfo+data))

        with open("image.raw", "wb") as f:
            f.write(image)
