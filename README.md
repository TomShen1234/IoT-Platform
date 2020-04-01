# IoT-Platform

---

## How to use this product?

First, download the iOS Application IPA file from the [Release tab](https://github.com/TomShen1234/IoT-Platform/releases/tag/1.0). 

Load the IPA onto your iPhone with [Cydia Impactor](http://www.cydiaimpactor.com/).

**Alternative**: Download the source code, install to your iPhone via Xcode. 

## Setting up the server

You will need a computer (or a [Raspberry Pi](https://www.raspberrypi.org/), 4th generation is recommended) as the server or main control hub. Internet connections is needed for setup. 

Install the following suite of software: python3, python3-pycurl, python3-zeroconf, apache2

If you're on a Raspberry Pi (or any other machine that runs the Linux system), you can use this one command to install all of them:

`sudo apt-get install python3 python3-pycurl python3-zeroconf apache2`

(You may have to enter your password)

Then, download the server codes, also from the [Release tab](https://github.com/TomShen1234/IoT-Platform/releases/tag/1.0), onto the Raspberry Pi server (or the computer you're using if you're not using the Pi). Unzip the files. If you're on the command line only version, this Terminal command will do the job:

`curl -SL https://github.com/TomShen1234/IoT-Platform/releases/download/1.0/server-v1.zip | tar -xf - -C .`

Copy the 3 files from the unzipped folder into the web server's directory: `/var/www/html`. If you're on the command line, you can use:
`sudo cp server/* /var/www/html`

(You may have to enter your password)

Now we get to the hardest part. You have to prepare the server to host the Python script we've just downloaded. This setup is quite complicated and is different for every system. If you're on the Raspberry Pi (or other Linux based systems), you can use [this tutorial](https://code-maven.com/set-up-cgi-with-apache). You can test this by going to the browser on your server and go to `http://localhost/discover.py`. If you get something along the line of: `{"devicesCount": 0, "devices": []}` (or something similar), you're all set up. If you see the source code of the program, you have a problem and will have to repeat the steps more carefully. 

## Setting up clients

For this step you have to use a Raspberry Pi (it cannot be the same one as your server). Make sure the Raspberry Pi is connected to the internet. 

Currently there is one supported class: Simple Switch. 

It allows you to toggle a light, a fan, etc. on and off. 

You can setup multiple switches on a single Raspberry Pi. 

First, install the same set of software you installed for the server. Here's the command once again:

`sudo apt-get install python3 python3-pycurl python3-zeroconf apache2`

Then, download and unzip the client files just like the server files, and place them into the web server's folder:

`curl -SL https://github.com/TomShen1234/IoT-Platform/releases/download/1.0/client-v1.zip | tar -xf - -C .
sudo cp client/* /var/www/html
`

Now [configure the client's web server just like you did before](https://code-maven.com/set-up-cgi-with-apache). 

## Writing configuration file

Create a new file in `/var/www/html` called `config.json`. edit it. 

Paste the following into the file:
```
[
    {
        "displayName":"<name of control>",
	    "parameterName":"state",
        "type":"switch",
        "className":"simpleswitch",
        "gpio":<port number here>
    }
]
```

Replace `<port number here>` with the port number you plugged in your switch into. Replace `<name of control>` with the display name of the switch (displayed in the app). 

To get help with the GPIO port number on the Raspberry Pi, see http://pinout.xyz. 

For multiple switches on one devices, follow this pattern:

```
[
    {
        "displayName":"<name of control 1>",
        "parameterName":"state",
        "type":"switch",
        "className":"simpleswitch",
        "gpio":<port number here>
    },
    {
        "displayName":"<name of control 2>",
        "parameterName":"state2",
        "type":"switch",
        "className":"simpleswitch",
        "gpio":<port number here>
    }
]
```

**IMPORTANT**: Make sure the `parameterName` (aka `state` and `state2`) do not repeat, that's the unique identifier for each switch!

For even more devices, just follow the pattern (note the comma at the end of the first closing bracket, that's important). 

And... you're done!
