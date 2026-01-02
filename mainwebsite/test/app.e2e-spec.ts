import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  // Home Page Tests
  describe('GET /', () => {
    it('should return 200 with HTML content', () => {
      return request(app.getHttpServer())
        .get('/')
        .expect(200)
        .expect((res) => {
          expect(res.type).toMatch(/html/);
        });
    });

    it('should return index view with title', () => {
      return request(app.getHttpServer())
        .get('/')
        .expect(200)
        .expect((res) => {
          expect(res.text).toBeDefined();
        });
    });
  });

  // Contact Form Tests
  describe('POST /contacts', () => {
    it('should fail without captcha token', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
          expect(res.body.message).toBeDefined();
        });
    });

    it('should fail with missing name field', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
          expect(res.body.message).toContain('Missing required fields');
        });
    });

    it('should fail with missing email field', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
          expect(res.body.message).toContain('Missing required fields');
        });
    });

    it('should fail with missing message field', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
          expect(res.body.message).toContain('Missing required fields');
        });
    });

    it('should fail with empty name', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: '',
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
        });
    });

    it('should fail with empty email', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: '',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
        });
    });

    it('should fail with empty message', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: '',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
        });
    });

    it('should fail with invalid captcha token', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'invalid-token',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
          expect(res.body.message).toContain('CAPTCHA validation failed');
        });
    });

    it('should accept all required fields in request body', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200);
    });

    it('should handle very long names', () => {
      const longName = 'A'.repeat(500);
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: longName,
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200);
    });

    it('should handle very long messages', () => {
      const longMessage = 'A'.repeat(5000);
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: longMessage,
          'g-recaptcha-response': 'test-token',
        })
        .expect(200);
    });

    it('should handle special characters in name', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: "Test User @#$%^&*()'\"<>",
          email: 'test@example.com',
          message: 'Test message',
          'g-recaptcha-response': 'test-token',
        })
        .expect(200);
    });

    it('should handle special characters in message', () => {
      return request(app.getHttpServer())
        .post('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: "Test message @#$%^&*()'\"<>",
          'g-recaptcha-response': 'test-token',
        })
        .expect(200);
    });
  });

  // Auth Verify CAPTCHA Tests
  describe('POST /auth/verify-captcha', () => {
    it('should return error for invalid captcha token', () => {
      return request(app.getHttpServer())
        .post('/auth/verify-captcha')
        .send({ token: 'invalid-token' })
        .expect(200)
        .expect((res) => {
          expect(res.body.success).toBe(false);
        });
    });

    it('should handle missing token', () => {
      return request(app.getHttpServer())
        .post('/auth/verify-captcha')
        .send({})
        .expect(200);
    });

    it('should handle null token', () => {
      return request(app.getHttpServer())
        .post('/auth/verify-captcha')
        .send({ token: null })
        .expect(200);
    });

    it('should handle empty string token', () => {
      return request(app.getHttpServer())
        .post('/auth/verify-captcha')
        .send({ token: '' })
        .expect(200);
    });

    it('should handle very long token string', () => {
      const longToken = 'A'.repeat(10000);
      return request(app.getHttpServer())
        .post('/auth/verify-captcha')
        .send({ token: longToken })
        .expect(200);
    });
  });

  // HTTP Method Tests
  describe('HTTP Method Testing', () => {
    it('should not accept PUT request on /contacts', () => {
      return request(app.getHttpServer())
        .put('/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
        })
        .expect(404);
    });

    it('should not accept DELETE request on /contacts', () => {
      return request(app.getHttpServer())
        .delete('/contacts')
        .expect(404);
    });

    it('should not accept PATCH request on /', () => {
      return request(app.getHttpServer())
        .patch('/')
        .expect(404);
    });

    it('should not accept POST request on /', () => {
      return request(app.getHttpServer())
        .post('/')
        .send({})
        .expect(404);
    });
  });

  // Invalid Routes Tests
  describe('Invalid Routes', () => {
    it('should return 404 for non-existent route', () => {
      return request(app.getHttpServer())
        .get('/non-existent-route')
        .expect(404);
    });

    it('should return 404 for /api/contacts route', () => {
      return request(app.getHttpServer())
        .post('/api/contacts')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
        })
        .expect(404);
    });

    it('should return 404 for /contact (singular) route', () => {
      return request(app.getHttpServer())
        .post('/contact')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          message: 'Test message',
        })
        .expect(404);
    });
  });
});
