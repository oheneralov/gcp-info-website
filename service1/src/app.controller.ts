import { Controller, Get, Post, Render, Body } from '@nestjs/common';
import { CaptchaService } from './captcha.service';
const sgMail = require('@sendgrid/mail');

@Controller()
export class AppController {
  constructor(private readonly captchaService: CaptchaService) { }

  @Get()
  @Render('index') // Render 'index' template
  getIndex() {
    return { title: 'Welcome to NestJS', message: 'This is a simple NestJS app.' };
  }

  sendMail() {
    sgMail.setApiKey('YOUR_SENDGRID_API_KEY');

    const msg = {
      to: 'recipient@example.com', // Recipient's email address
      from: 'your-email@example.com', // Verified sender email
      subject: 'Test Email from GCP',
      text: 'Hello, this is a test email sent from GCP using SendGrid!',
      html: '<strong>Hello, this is a test email sent from GCP using SendGrid!</strong>',
    };

    sgMail
      .send(msg)
      .then(() => {
        console.log('Email sent successfully!');
      })
      .catch((error) => {
        console.error('Error sending email:', error);
      });

  }

  @Post('contacts') // POST /contacts
  async handleContactForm(@Body() body: any) {
    const token = body['g-recaptcha-response'];
    console.log(token);
    const { name, email, message } = body;

    // Verify CAPTCHA
    const isCaptchaValid = await this.captchaService.verifyCaptcha(token);
    if (!isCaptchaValid) {
      console.log('CAPTCHA validation failed');
      return { success: false, message: 'CAPTCHA validation failed' };
    }

    // Handle the form submission (e.g., send email, save to database)
    console.log('Form submitted:', { name, email, message });

    return { success: true, message: 'MF000' };
  }
}


