import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PassportsService } from './passports.service';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';

@ApiTags('passports')
@ApiBearerAuth()
@Controller('me/passports')
export class PassportsController {
  constructor(private readonly passports: PassportsService) {}

  @Get()
  list(@CurrentUser() user: AuthUser) {
    return this.passports.listForUser(user.sub);
  }

  @Get(':id')
  async detail(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    const p = await this.passports.getPassportForUser(user.sub, id);
    if (!p) throw new NotFoundException('Passport not found');
    return p;
  }
}
