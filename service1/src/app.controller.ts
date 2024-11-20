import { Controller, Get, Render } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  @Render('index') // Render 'index' template
  getIndex() {
    return { title: 'Welcome to NestJS', message: 'This is a simple NestJS app.' };
  }
}
