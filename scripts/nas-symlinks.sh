# Create symlinks from NAS to local directories
## Photos
ln -s /run/user/1000/gvfs/sftp:host=NASIPADDRESS,user=oliver/homes/Oliver/Photos ~/Pictures/
## Pics
ln -s /run/user/1000/gvfs/sftp:host=NASIPADDRESS,user=oliver/homes/Oliver/04_Pics ~/Pictures/04_Pics
## Videos
ln -s /run/user/1000/gvfs/sftp:host=NASIPADDRESS,user=oliver/homes/Oliver/03_Videos ~/Videos/03_Videos
## Music
ln -s /run/user/1000/gvfs/sftp:host=NASIPADDRESS,user=oliver/homes/Oliver/Music ~/Music
## Documents
ln -s /run/user/1000/gvfs/sftp:host=NASIPADDRESS,user=oliver/homes/Oliver/01_Documents ~/Documents/