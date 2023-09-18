<p align="center">
   <img src="https://dietpi.com/images/dietpi-logo_240x80.png" width="240" height="80"> <img src="https://nextcloud.com/wp-content/uploads/2022/11/nextcloud-logo.svg" width="120" height="85">
</p>

# FAST PATH
For those of you who are already familiar with this repository. 

 	cd / && sudo apt install git -y && git clone https://github.com/lstavares84/nextcloud.git && rm nextcloud/README.md && sudo mv nextcloud/*.* / && sudo chmod +x *.sh && sudo chmod +x /setup-tools/*.sh && sudo ./ncdietpi.sh

# NEXTCLOUD in DietPI for Native PC (Bios/CSM)

Scripts to automate the installation and configuration of Nextcloud on PCs (Not for SBC, Raspberry Pi, Orange, Rock, ect.)
Written in partnership with @edsonsbj (https://github.com/edsonsbj). Thanks a lot, pal!

# THIS SCRIPT WAS TESTED IN:
	[ ] Raspberry Pi 4B+
	[ ] Raspberry Pi 400
	[X] PC Bios
	[X] Internal Sata HDD/SSD
 	[X] External USB HDD/SSD  
	[ ] Live USB OS
 	[X] OS Installed in Internal HDD/SDD
	[ ] NoIp Domain
	[ ] Cloudflare Domain
	[X] Duckdns Domain
	[ ] This script install OnlyOffice
	[X] This script DOES NOT install Onlyoffice
	[ ] This script formats the external HDD/SDD or Flash USB
	[X] This script DOES NOT formats the external HDD/SDD or Flash USB
	[ ] This script formats the external HDD/SDD or Flash USB as EXT4
	[ ] This script formats the external HDD/SDD or Flash USB
 

## STEP 1: Download DietPi Image

🔗 https://dietpi.com/#download
<p align="center">
<img src="https://github.com/lstavares84/nextcloud/assets/61010791/697b969d-eb9c-4687-b6f1-39f59d536d44"/>
</p>

## STEP 2: Flash Installer Image to USB Driver

🔗 Download Rufus: https://rufus.ie/pt_BR/

<p align="center">
<img src="https://github.com/lstavares84/nextcloud/assets/61010791/a2fa06b5-142e-45c8-96c7-c0f0050819dc"/>
</p>

## STEP 3: Boot and Install DietPi

🔗 Procedure: https://dietpi.com/docs/install/

<p align="center">
<img src="https://github.com/lstavares84/nextcloud/assets/61010791/0b173505-22d6-462d-884b-f5e7da18e301"/>
</p>


## STEP 4: After Installation

After the install OS the system will shutdown. Remove the flash usb, turn on PC again and follow the steps below.

![image](https://github.com/lstavares84/nextcloud/assets/61010791/772cfdb6-4803-456b-ac4b-f8533f02fccf)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/66cb39da-50b2-44af-b9db-ebdc267ee89d)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/c794f951-9ab5-464c-be0c-7151afed449a)

⚠️ ⚠️ ⚠️  Do not install anything! Go direct to Install Option, press TAB to go to OK and press ENTER!
![image](https://github.com/lstavares84/nextcloud/assets/61010791/4e6fe183-3057-41dd-a71f-cbc2e4842e3d)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/7209cf43-dfc3-4dd9-b0c5-16ed7e6c4d44)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/a19bb6e2-415c-4410-a119-32cd8e95237a)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/b33de81b-ae79-48c0-91dc-5a1d7d9a6e4b)

⚠️ ⚠️ ⚠️  Everything is done when you see this screen.
![image](https://github.com/lstavares84/nextcloud/assets/61010791/2c0a3b3a-e0cd-49ad-a9e4-dc46c8439264)

## STEP 5: Now, let's run the script that will install everything you need to run Nextcloud.

Copy and paste the command below in the screen above.  It can take a while. Be patience and wait for the screen below

 	cd / && sudo apt install git -y && git clone https://github.com/lstavares84/nextcloud.git && sudo mv nextcloud/*.sh / && sudo chmod +x *.sh && sudo ./ncdietpi.sh

⚠️ ⚠️ ⚠️  If... BIG IF here... the screen below shows up, choose Apache. But if it don't shows up... relax and continue.
![image](https://github.com/lstavares84/nextcloud/assets/61010791/b65c5684-39d7-447b-8cef-3aa5f85f836d)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/7439aab7-ba98-4423-b27d-b390c6839bf1)

⚠️ ⚠️ ⚠️  If eveything is OK, type CONTINUE. If NOK, flash a new image and start again.
![image](https://github.com/lstavares84/nextcloud/assets/61010791/0f79b397-90de-4553-954e-de9466312870)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/59a9b271-a0e3-43a7-8776-d0115b43200b)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/e4a0db48-6527-4c06-a376-4c79d2ab449c)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/65ba3f4c-b99b-4f6c-a76d-1f843b4e3fc2)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/fb63aca8-98e2-4365-821f-88bfe11eea71)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/275e2b40-386b-4813-8d48-9ffcfc322d93)

http://192.168.0.70:81/ (not https)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/537088b4-d86c-47a5-b8d5-0e029177e445)


![image](https://github.com/lstavares84/nextcloud/assets/61010791/33277549-06ee-4fea-8d6c-de43f41931db)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/9babd530-77b5-4a9d-b0c2-12911bfcb6a3)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/4e0e67cf-c3e5-4fb8-bd65-db9c7deac3a2)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/93f7a97b-574c-465d-b472-4f386b972323)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/5b57e880-9230-4452-8c5d-a128468cc866)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/2790c9bf-754f-4566-8a77-9f013c1ee1f4)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/2c02cd1e-63ac-4331-927b-688d12d5cfad)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/20619dbe-7568-4537-9a2a-153fa7a1e844)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/4ef1739e-89b7-41e9-bc72-b471a725983f)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/06c33414-6b79-4076-a349-2c853604aac5)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/42b227f9-18fc-4350-a9d9-0d1e1977144a)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/77793b3e-0bdc-4c42-9053-43c25191d9e0)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/096888c5-b208-4ecd-8e4c-a7a8188d40dd)


![image](https://github.com/lstavares84/nextcloud/assets/61010791/9b81ed13-5f3d-4fda-af70-130aeaeacd97)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/258e99b6-ad64-4497-83b6-f3f6fc3be694)
![image](https://github.com/lstavares84/nextcloud/assets/61010791/5b157be7-be27-4de6-8b56-f83483f39dbd)

![image](https://github.com/lstavares84/nextcloud/assets/61010791/a68a1144-6bc7-435b-9f20-df10a816cb0d)


![image](https://github.com/lstavares84/nextcloud/assets/61010791/a3dbb35d-b84e-4a0c-81d9-f251ee84aad3)


After Dietpi First Boot:

cd / && wget https://raw.githubusercontent.com/lstavares84/nextcloud/master/nextcloud-dietpi.sh -O nextcloud-dietpi.sh && chmod +x nextcloud-dietpi.sh && ./nextcloud-dietpi.sh
