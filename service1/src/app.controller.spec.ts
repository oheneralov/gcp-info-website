import { AppService } from './app.service';

describe('AppController', () => {

  describe('root', () => {
    it('should return "Hello World!"', () => {
      const appService = new AppService();
      expect(appService.getHello()).toBe('Hello World!');
    });
  });
});
