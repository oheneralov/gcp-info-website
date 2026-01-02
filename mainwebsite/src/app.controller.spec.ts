import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { CaptchaService } from './captcha.service';
import { ContactService } from './contact/contact.service';
import { LoggingService } from './logging.service';

describe('AppController', () => {
  let controller: AppController;
  let captchaService: CaptchaService;
  let contactService: ContactService;
  let loggingService: LoggingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: CaptchaService,
          useValue: {
            verifyCaptcha: jest.fn(),
          },
        },
        {
          provide: ContactService,
          useValue: {
            createContact: jest.fn(),
          },
        },
        {
          provide: LoggingService,
          useValue: {
            log: jest.fn(),
            warn: jest.fn(),
            error: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<AppController>(AppController);
    captchaService = module.get<CaptchaService>(CaptchaService);
    contactService = module.get<ContactService>(ContactService);
    loggingService = module.get<LoggingService>(LoggingService);
  });

  describe('getIndex', () => {
    it('should return welcome message', () => {
      const result = controller.getIndex();
      expect(result).toBeDefined();
      expect(result.title).toBe('Welcome!');
      expect(result.message).toContain('Do not use it directly');
    });
  });

  describe('handleContactForm', () => {
    it('should reject request with missing required fields', async () => {
      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'token',
        name: 'John',
      });

      expect(result.success).toBe(false);
      expect(result.message).toBe('Missing required fields');
    });

    it('should reject request without email', async () => {
      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'token',
        name: 'John',
        message: 'Hello',
      });

      expect(result.success).toBe(false);
      expect(result.message).toBe('Missing required fields');
    });

    it('should reject request without message', async () => {
      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'token',
        name: 'John',
        email: 'john@example.com',
      });

      expect(result.success).toBe(false);
      expect(result.message).toBe('Missing required fields');
    });

    it('should reject request without captcha token', async () => {
      const result = await controller.handleContactForm({
        name: 'John',
        email: 'john@example.com',
        message: 'Hello',
      });

      expect(result.success).toBe(false);
    });

    it('should reject request with invalid captcha', async () => {
      jest.spyOn(captchaService, 'verifyCaptcha').mockResolvedValue(false);

      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'invalid-token',
        name: 'John',
        email: 'john@example.com',
        message: 'Hello',
      });

      expect(result.success).toBe(false);
      expect(result.message).toBe('CAPTCHA validation failed');
      expect(loggingService.warn).toHaveBeenCalled();
    });

    it('should save contact and send email on valid submission', async () => {
      jest.spyOn(captchaService, 'verifyCaptcha').mockResolvedValue(true);
      jest.spyOn(contactService, 'createContact').mockResolvedValue({
        id: 1,
        name: 'John',
        email: 'john@example.com',
        message: 'Hello',
        createdAt: new Date(),
      });

      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'valid-token',
        name: 'John',
        email: 'john@example.com',
        message: 'Hello World',
      });

      expect(result.success).toBe(true);
      expect(result.message).toBe('Contact saved successfully');
      expect(contactService.createContact).toHaveBeenCalledWith(
        'John',
        'john@example.com',
        'Hello World',
      );
      expect(loggingService.log).toHaveBeenCalled();
    });

    it('should handle database errors gracefully', async () => {
      jest.spyOn(captchaService, 'verifyCaptcha').mockResolvedValue(true);
      jest
        .spyOn(contactService, 'createContact')
        .mockRejectedValue(new Error('DB Error'));

      const result = await controller.handleContactForm({
        'g-recaptcha-response': 'valid-token',
        name: 'John',
        email: 'john@example.com',
        message: 'Hello',
      });

      expect(result.success).toBe(false);
      expect(result.message).toBe('Error processing form');
      expect(loggingService.error).toHaveBeenCalled();
    });

    it('should log captcha verification', async () => {
      jest.spyOn(captchaService, 'verifyCaptcha').mockResolvedValue(false);

      await controller.handleContactForm({
        'g-recaptcha-response': 'token',
        name: 'John',
        email: 'john@example.com',
        message: 'Hello',
      });

      expect(captchaService.verifyCaptcha).toHaveBeenCalledWith('token');
    });
  });
});
