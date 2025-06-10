/*
import { Injectable } from '@nestjs/common';
import { LoggerService } from '@nestjs/common';
import { createLogger, transports, format } from 'winston';
import * as Logging from '@google-cloud/logging';
import { LoggingWinston } from '@google-cloud/logging-winston';
const winston = require('winston');


@Injectable()
export class LoggingService implements LoggerService {
  private logger;

  constructor() {
    const loggingWinston = new LoggingWinston();

    // Create a Winston logger with Google Cloud Logging transport
    this.logger = winston.createLogger({
        level: 'info',
        transports: [
          new winston.transports.Console(),
          // Add Cloud Logging
          loggingWinston,
        ],
      });
  }

  log(message: any) {
    this.logger.info(message);
  }

  error(message: any, trace: string) {
    this.logger.error(message, trace);
  }

  warn(message: any) {
    this.logger.warn(message);
  }

  debug(message: any) {
    this.logger.debug(message);
  }

  verbose(message: any) {
    this.logger.verbose(message);
  }
}
*/