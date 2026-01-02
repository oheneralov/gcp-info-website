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

  it('/ (GET) - should return 200 with HTML content', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect((res) => {
        expect(res.type).toMatch(/html/);
      });
  });

  it('/ (POST to /contacts) - should fail without captcha token', () => {
    return request(app.getHttpServer())
      .post('/contacts')
      .send({
        name: 'Test User',
        email: 'test@example.com',
        message: 'Test message',
      })
      .expect(400);
  });
});
