import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Contact } from '../entities/contact.entity';

@Injectable()
export class ContactService {
  constructor(
    @InjectRepository(Contact)
    private readonly contactRepository: Repository<Contact>,
  ) {}

  async createContact(name: string, email: string, message?: string): Promise<Contact> {
    const newContact = this.contactRepository.create({ name, email, message });
    return this.contactRepository.save(newContact);
  }
}
