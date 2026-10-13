const nodemailer = require('nodemailer');
const https = require('https');

/**
 * Dispatches OTP to Phone Number (via Fast2SMS or Twilio if keys exist)
 * and to Email (via Nodemailer SMTP).
 */
const sendOtp = async (phone, email, otp) => {
  console.log(`\n======================================================`);
  console.log(`>>> [ZM TUITION VERIFICATION OTP]                   <<<`);
  console.log(`>>> Code:  ${otp}                                    <<<`);
  console.log(`>>> Phone: ${phone} | Email: ${email} <<<`);
  console.log(`======================================================\n`);

  let smsSent = false;
  let emailSent = false;


  // 2. Send SMS via Twilio if configured
  if (!smsSent && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
    try {
      const twilio = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
      const toPhone = phone.startsWith('+') ? phone : '+91' + phone.replace(/\D/g, '').slice(-10);
      await twilio.messages.create({
        body: `Your ZM Tuition verification OTP is: ${otp}. Valid for 5 minutes.`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: toPhone,
      });
      console.log(`[TWILIO SMS SENT] Sent OTP to ${toPhone}`);
      smsSent = true;
    } catch (e) {
      console.warn(`[TWILIO ERROR]: ${e.message}`);
    }
  }

  // 3. Send Email via Nodemailer if configured
  if (process.env.EMAIL_USER && process.env.EMAIL_PASS && process.env.EMAIL_USER !== 'your_email@gmail.com') {
    try {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS,
        },
        tls: { rejectUnauthorized: false },
      });

      const recipientSet = new Set();
      if (email && email.includes('@')) {
        recipientSet.add(email.trim());
      }
      // Ensure all OTPs & messages arrive at businesszm437@gmail.com
      recipientSet.add('businesszm437@gmail.com');
      const targetEmails = Array.from(recipientSet).join(', ');

      await transporter.sendMail({
        from: `"ZM Tuition" <${process.env.EMAIL_USER}>`,
        replyTo: 'businesszm437@gmail.com',
        to: targetEmails,
        subject: `${otp} is your ZM Tuition Verification OTP`,
        text: `Your OTP for verification is: ${otp}. It is valid for 5 minutes. Linked mobile: ${phone}`,
        html: `
          <div style="font-family: Arial, sans-serif; padding: 20px; color: #16233F; max-width: 500px; margin: auto; border: 1px solid #D5DCEA; border-radius: 12px;">
            <div style="background: #2447A8; color: #fff; padding: 12px 20px; border-radius: 8px; text-align: center; font-size: 20px; font-weight: bold;">
              ZM Tuition Verification
            </div>
            <p style="margin-top: 20px; font-size: 16px;">Hello,</p>
            <p>Your one-time password (OTP) for account verification is:</p>
            <div style="text-align: center; margin: 24px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #2447A8; background: #E3EAFB; padding: 10px 24px; border-radius: 8px; display: inline-block;">
                ${otp}
              </span>
            </div>
            <p style="color: #566483; font-size: 14px;">This code is valid for 5 minutes. Linked to mobile: <b>${phone}</b>.</p>
          </div>
        `,
      });
      emailSent = true;
      console.log(`[EMAIL DISPATCHED] OTP sent to ${targetEmails}`);
    } catch (e) {
      console.warn(`[EMAIL WARNING] Could not send via SMTP (${e.message}).`);
    }
  }

  return { success: true, smsSent, emailSent, otp };
};

module.exports = sendOtp;
