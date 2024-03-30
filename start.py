import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.mime.image import MIMEImage

import csv
import time

EMAIL_ADDRESS = "monashactuary.president@gmail.com"
EMAIL_PASSWORD = ""
CSV_FILE_PATH = "//Users//zachbushby//Documents//edu//data_science//Projects//Actuarial Assassins//df_randomised.csv"

# Read recipient names and email addresses from the CSV file
NAMES = []
RECIPIENT_ADDRESSES = []
TARGETS = []
PASSWORDS = []

with open(CSV_FILE_PATH, 'r') as csv_file:
    csv_reader = csv.DictReader(csv_file)
    for row in csv_reader:
        # Assuming 'First name' and 'Last name' are the headers for recipient names
        name = f"{row['names']}"
        email = row['email']
        target = row['target_names']
        password = row['own_password']
        NAMES.append(name)
        RECIPIENT_ADDRESSES.append(email)
        TARGETS.append(target)
        PASSWORDS.append(password)

# Compose and send emails
for name, recipient_address, target, password in zip(NAMES, RECIPIENT_ADDRESSES, TARGETS, PASSWORDS):
    time.sleep(13)
    msg = MIMEMultipart()
    # Custom signature with HTML formatting


    # Email content
    html_content = f"""
<p>Hey {name},</p>

<p>Your mission, if you choose to accept it, is to whisper 'you're dead' into the ear of your target so that only your target can hear. You must not be heard by any one else because your target will survive and they'll know you are after them</p>
<p>Your First Target is:</p>
<h3>{target}</h3>
<h3>Your Password is {password}</h3>
<p>If you successfully kill someone, you must enter in your login (email, password) on this website:</p>
<p style="color: black;"><a href="https://5csp3a-zach-bushby.shinyapps.io/AssassinGame/" style="color: #00008B;">Actuarial Assassins</a></p>
<p>Once you put your victim's password in your portal you will recieve you're next target!</p>
<p>Good Luck!</p>


<div style="font-family: Arial, sans-serif; color: #00008B; font-style: italic; font-weight: bold;">
    <p style="color: navy;">Zach Bushby</p>
    <p style="color: black; font-style: italic;">President</p>
    <p style="color: black;"><strong>Monash Actuarial Students Society</strong></p>
    <p style="color: black;">Campus Centre 21 Chancellors Walk<br>
    Monash University, VIC 3800</p>
    <p style="color: black;"><a href="http://monashactuary.com.au" style="color: #00008B;">monashactuary.com.au</a></p>
    <img src="cid:logo" alt="MASS Logo" style="width: 100px; height: auto;">
</div>
    """

    # Attach HTML content
    msg.attach(MIMEText(html_content, 'html'))

    # Attach logo image
    with open("//Users//zachbushby//Documents//edu//MASS//Data//Welcome New Members//Data//MASS.png", "rb") as logo_file:
        logo = logo_file.read()
    logo_part = MIMEImage(logo)
    logo_part.add_header('Content-ID', '<logo>')
    msg.attach(logo_part)

    # Set the email subject, sender, and recipient
    msg['Subject'] = f"Hey {name}! Your Mission Awaits You"
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = recipient_address

    # Send the message via SMTP server.
    with smtplib.SMTP('smtp.gmail.com', 587) as smtp:
        smtp.starttls()
        smtp.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        smtp.sendmail(EMAIL_ADDRESS, recipient_address, msg.as_string())
        print(f"Email sent for {name} with {recipient_address}")
