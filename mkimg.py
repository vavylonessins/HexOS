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
    if a.startswith("--device="):
        device = a[9:]

os.system("rm image.img")
os.system("dd if=/dev/zero of=image.img bs=1M count=64")
os.system("sudo mkfs.fat -F 32 image.img")
if not os.path.exists("/mnt/vfat32"):
    os.system("sudo mkdir /mnt/vfat32")
os.system("sudo mount -o loop image.img /mnt/vfat32")
os.system(f"sudo cp -r {os.path.abspath(dst).removesuffix('/')}/* /mnt/vfat32")
os.system("sudo umount /mnt/vfat32")
os.system("chown talisman image.img")

with open("image.img", "rb") as f:
    image = f.read()

del f

prtofs = 0xC00

print(prt[62:], len(prt[62:]))

# phase 1 - fix partition mbr
image = image[:prtofs] + prt[:11] + image[prtofs+11:]  # fix version specification
image = image[:prtofs+46] + prt[46:] + image[prtofs+512:]  # add bootloader

# phase 2 - fix image mbr
image = mbr[:446] + image[446:]

with open("image.img", "wb") as f:
    f.write(image)
