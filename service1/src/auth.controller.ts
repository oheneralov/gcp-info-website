import { Controller, Post, Body } from '@nestjs/common';
import { CaptchaService } from './captcha.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly captchaService: CaptchaService) {}

  @Post('verify-captcha')
  async verifyCaptcha(@Body('token') token: string): Promise<{ success: boolean }> {
    const isValid = await this.captchaService.verifyCaptcha(token);

    if (!isValid) {
      return { success: false };
    }

    return { success: true };
  }
}
