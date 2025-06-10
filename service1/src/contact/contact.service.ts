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

  async createContact(name: string, email: string): Promise<Contact> {
    const newUser = this.contactRepository.create({ name, email }); // Create a new instance of the User entity.
    return this.contactRepository.save(newUser); // Save it to the database.
  }
}
