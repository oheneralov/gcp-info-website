import { Controller, Get, Post, Render, Body } from '@nestjs/common';
import { CaptchaService } from './captcha.service';
import sgMail from '@sendgrid/mail';
import { ContactService } from './contact/contact.service';
import { LoggingService } from './logging.service';

@Controller()
export class AppController {
  constructor(
    private readonly captchaService: CaptchaService,
    private readonly contactService: ContactService,
    private readonly loggingService: LoggingService,
  ) {}

  @Get()
  @Render('index') // Render 'index' template
  getIndex() {
    return { title: 'Welcome!', message: 'Do not use it directly' };
  }

  private async sendMail(name: string, email: string, message: string): Promise<void> {
    sgMail.setApiKey(process.env.SENDGRID_API_KEY || '');

    const msg = {
      to: process.env.CONTACT_EMAIL || 'admin@example.com',
      from: process.env.SENDER_EMAIL || 'noreply@example.com',
      replyTo: email,
      subject: `Contact Form: ${name}`,
      text: message,
      html: `<strong>Name:</strong> ${name}<br><strong>Message:</strong> ${message}`,
    };

    try {
      await sgMail.send(msg);
      this.loggingService.log(`Email sent successfully from ${email}`);
    } catch (error) {
      this.loggingService.error(`Error sending email: ${error}`, error.stack);
    }
  }
  

  @Post('contacts')
  async handleContactForm(@Body() body: any) {
    const token = body['g-recaptcha-response'];
    const { name, email, message } = body;

    if (!name || !email || !message) {
      return { success: false, message: 'Missing required fields' };
    }

    // Verify CAPTCHA
    const isCaptchaValid = await this.captchaService.verifyCaptcha(token);
    if (!isCaptchaValid) {
      this.loggingService.warn('CAPTCHA validation failed for email: ' + email);
      return { success: false, message: 'CAPTCHA validation failed' };
    }

    try {
      // Save contact to database
      await this.contactService.createContact(name, email, message);
      
      // Send email notification
      await this.sendMail(name, email, message);
      
      this.loggingService.log(`Contact form submitted by ${email}`);
      return { success: true, message: 'Contact saved successfully' };
    } catch (error) {
      this.loggingService.error(`Error processing contact form: ${error}`, error.stack);
      return { success: false, message: 'Error processing form' };
    }
  }
}


