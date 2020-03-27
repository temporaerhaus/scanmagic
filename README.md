# scanmagic

Our printer (a Brother MFC-L8900CDW) supports scanning directly in network shares, provided over SMB.
The SMB share is accessible for everyone in the [verschwörhaus](https://verschwoerhaus.de) network.
Sadly, the printer is not able to OCR the scanned stuff by itself - and this is the reason for the _scanmagic_ script.


### Installation
You need `docker` (for the ocr-container) and [`entr`](http://entrproject.org).

Pull the ocr container image: `docker pull jbarlow83/ocrmypdf:latest`

Configure `scanmagic.sh` by copying `.env.sample` to `.env`.

Add scanmagic as an systemd unit by copying `scanmagic.service` to `/etc/systemctl/system/`.

