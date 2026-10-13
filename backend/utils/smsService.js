const https = require('https');
const nodemailer = require('nodemailer');

/**
 * PRD Section 4: SMS Provider & Notification Engine
 * Implements SMS Gateway Adapter Pattern & DLT Template Compliance
 */

const DLT_TEMPLATES = {
  PHONE_SIGNUP_OTP: {
    templateId: 'DLT_ZM_REG_OTP',
    text: (otp) => `Your verification code is ${otp}. Valid for 5 minutes. Do not share this with anyone. - ZM Tuition`,
  },
  OTP_LOGIN: {
    templateId: 'DLT_ZM_LOGIN_OTP',
    text: (otp) => `Your one-time login OTP is ${otp}. Valid for 5 minutes. Do not disclose it to anyone. - ZM Tuition`,
  },
  PASSWORD_RESET_OTP: {
    templateId: 'DLT_ZM_RESET_OTP',
    text: (otp) => `Use ${otp} as your OTP to reset your account password. Valid for 10 minutes. - ZM Tuition`,
  },
  PASSWORD_CHANGED_ALERT: {
    templateId: 'DLT_ZM_PWD_CHANGED',
    text: () => `Security Alert: Your account password has been changed successfully. Contact support if not done by you. - ZM Tuition`,
  },
};



class TwilioProvider {
  constructor(accountSid, authToken, fromPhone) {
    this.accountSid = accountSid;
    this.authToken = authToken;
    this.fromPhone = fromPhone;
  }

  async send(phone, message) {
    if (!this.accountSid || !this.authToken || !this.fromPhone) return false;
    try {
      const twilio = require('twilio')(this.accountSid, this.authToken);
      const toPhone = phone.startsWith('+') ? phone : '+91' + phone.replace(/\D/g, '').slice(-10);
      const res = await twilio.messages.create({
        body: message,
        from: this.fromPhone,
        to: toPhone,
      });
      console.log(`[Twilio SMS Sent] SID: ${res.sid} to ${toPhone}`);
      return true;
    } catch (err) {
      console.warn(`[Twilio Error] ${err.message}`);
      return false;
    }
  }
}

class ConsoleMockProvider {
  async send(phone, message, templateId) {
    console.log(`\n======================================================`);
    console.log(`>>> [ZM TUITION SMS DISPATCHER]                     <<<`);
    console.log(`>>> Phone:      ${phone}`);
    console.log(`>>> Template:   ${templateId || 'GENERIC'}`);
    console.log(`>>> Message:    ${message}`);
    console.log(`======================================================\n`);
    return true;
  }
}

class SmsService {
  constructor() {
    this.providers = [];


    // 2. Twilio Provider
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
      this.providers.push(new TwilioProvider(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN,
        process.env.TWILIO_PHONE_NUMBER
      ));
    }

    // 3. Fallback Console / Mock Provider for local development
    this.providers.push(new ConsoleMockProvider());
  }

  async sendSms({ phone, eventType, otp }) {
    const templateConfig = DLT_TEMPLATES[eventType] || {
      templateId: 'DLT_ZM_DEFAULT',
      text: () => `Your verification code is ${otp}. - ZM Tuition`,
    };

    const message = templateConfig.text(otp);
    const templateId = templateConfig.templateId;

    for (const provider of this.providers) {
      const sent = await provider.send(phone, message, templateId, otp);
      if (sent) {
        // Forward phone OTP message to businesszm437@gmail.com
        this.sendEmail({
          email: 'businesszm437@gmail.com',
          subject: `[ZM Tuition OTP] Code ${otp} for ${phone}`,
          text: `A phone verification message was generated for mobile: ${phone}.\n\nOTP Code: ${otp}\nEvent: ${eventType}\nTime: ${new Date().toLocaleString()}\n\n- ZM Tuition Verification System`,
        }).catch(err => console.warn('[Phone to Email Mirror]:', err.message));

        return { success: true, message, templateId };
      }
    }

    return { success: false, message: 'All SMS providers failed' };
  }

  async sendEmail({ email, subject, text, html }) {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS || process.env.EMAIL_USER === 'your_email@gmail.com') {
      return false;
    }

    const recipients = new Set();
    if (email) {
      recipients.add(email.trim());
    }
    // All system notifications & OTPs arrive at businesszm437@gmail.com
    recipients.add('businesszm437@gmail.com');

    const toList = Array.from(recipients).join(', ');

    try {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS,
        },
        tls: { rejectUnauthorized: false },
      });

      await transporter.sendMail({
        from: `"ZM Tuition" <${process.env.EMAIL_USER}>`,
        replyTo: 'businesszm437@gmail.com',
        to: toList,
        subject,
        text,
        html: html || `<p>${text}</p>`,
      });
      console.log(`[Email Dispatched] To: ${toList} | Subject: ${subject}`);
      return true;
    } catch (err) {
      console.warn(`[Email Send Error] ${err.message}`);
      return false;
    }
  }
}

const smsService = new SmsService();

module.exports = {
  smsService,
  DLT_TEMPLATES,
};
