import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class CaptchaService {
  private readonly recaptchaVerifyUrl = 'https://www.google.com/recaptcha/api/siteverify';

  async verifyCaptcha(token: string): Promise<boolean> {
    try {
      const response = await axios.post(this.recaptchaVerifyUrl, null, {
        params: {
          secret: '6Lc3n40qAAAAAE8oPWTHHL0XrgB3KqjcB8k5wkme', // Store this securely
          response: token,
        },
      });

      return response.data.success;
    } catch (error) {
      throw new HttpException('CAPTCHA verification failed', HttpStatus.BAD_REQUEST);
    }
  }
}
