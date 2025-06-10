import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CaptchaService } from './captcha.service';
//import { LoggingService } from './logging.service';
import { TypeOrmModule } from '@nestjs/typeorm';


@Module({
  imports: [
    /*
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: '10.7.112.3', // Use '127.0.0.1' if using the Cloud SQL Proxy
      port: 3306,
      username: 'clever-spirit-417020:europe-west1:nextjs-app-db',
      password: 'your-password',
      database: 'your-database',
      entities: ],
      synchronize: true, 
    }),
    */
  ],
  controllers: [AppController],
  providers: [AppService, CaptchaService, /*LoggingService*/],
})
export class AppModule {}
