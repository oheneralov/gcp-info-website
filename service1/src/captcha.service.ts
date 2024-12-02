import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class CaptchaService {
  private readonly recaptchaVerifyUrl = 'https://www.google.com/recaptcha/api/siteverify';

  getSecret(): string {
    return process.env.recaptcha_key || 'default';
  }

  async verifyCaptcha(token: string): Promise<boolean> {
    try {
      const response = await axios.post(this.recaptchaVerifyUrl, null, {
        params: {
          secret: this.getSecret(), // Store this securely
          response: token,
        },
      });

      return response.data.success;
    } catch (error) {
      throw new HttpException('CAPTCHA verification failed', HttpStatus.BAD_REQUEST);
    }
  }
}
