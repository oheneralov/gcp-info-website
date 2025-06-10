import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
//import { LoggingService } from './logging.service'; // Import the LoggingService


async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // Serve static files from the 'public' directory
  app.useStaticAssets(join(__dirname, '..', 'public'));

  // Set up Handlebars as the template engine
  app.setBaseViewsDir(join(__dirname, '..', 'views'));
  app.setViewEngine('hbs');

  // Use the custom logging service
  /*
  const loggingService = app.get(LoggingService);
  app.useLogger(loggingService);*/

  await app.listen(3000);
}
bootstrap();

