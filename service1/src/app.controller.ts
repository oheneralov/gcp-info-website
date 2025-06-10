import { Controller, Get, Post, Render, Body } from '@nestjs/common';
import { CaptchaService } from './captcha.service';
// const sgMail = require('@sendgrid/mail');
//import { ContactService } from './contact/contact.service';
//import { Contact } from './entities/contact.entity';
// import { LoggingService } from './logging.service';

@Controller()
export class AppController {
  constructor(
    private readonly captchaService: CaptchaService,
    /*private readonly loggingService: LoggingService*/) { }

  @Get()
  @Render('index') // Render 'index' template
  getIndex() {
    return { title: 'Welcome to NestJS', message: 'This is a simple NestJS app.' };
  }
/*
  sendMail(name, email, message) {
    sgMail.setApiKey('SENDGRID_API_KEY');

    const msg = {
      to: 'justnicemusic2023@gmail.com', // Recipient's email address
      from: email, // Verified sender email
      subject: 'Email from GCP website',
      text: message,
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
  */

  @Post('contacts') // POST /contacts
  async handleContactForm(@Body() body: any) {
    const token = body['g-recaptcha-response'];
    // console.log(token);
    const { name, email, message } = body;

    // Verify CAPTCHA
    const isCaptchaValid = await this.captchaService.verifyCaptcha(token);
    if (!isCaptchaValid) {
      console.log('CAPTCHA validation failed');
      return { success: false, message: 'CAPTCHA validation failed' };
    }

    // Handle the form submission (e.g., send email, save to database)
    // console.log('Form submitted:', { name, email, message });
    // this.contactService.createContact(name, email);
    // this.loggingService.log('Form submitted: ' + JSON.stringify({ name, email, message }));
    

    return { success: true, message: 'MF000' };
  }
}


