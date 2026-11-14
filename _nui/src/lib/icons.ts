import ArrowLineDownIcon from 'phosphor-svelte/lib/ArrowLineDownIcon';
import ArrowUUpLeftIcon from 'phosphor-svelte/lib/ArrowUUpLeftIcon';
import CarIcon from 'phosphor-svelte/lib/CarIcon';
import CopyIcon from 'phosphor-svelte/lib/CopyIcon';
import CubeIcon from 'phosphor-svelte/lib/CubeIcon';
import EyeIcon from 'phosphor-svelte/lib/EyeIcon';
import FlagIcon from 'phosphor-svelte/lib/FlagIcon';
import GasPumpIcon from 'phosphor-svelte/lib/GasPumpIcon';
import HardDrivesIcon from 'phosphor-svelte/lib/HardDrivesIcon';
import HeartIcon from 'phosphor-svelte/lib/HeartIcon';
import MapPinIcon from 'phosphor-svelte/lib/MapPinIcon';
import MoneyIcon from 'phosphor-svelte/lib/MoneyIcon';
import NavigationArrowIcon from 'phosphor-svelte/lib/NavigationArrowIcon';
import ProhibitIcon from 'phosphor-svelte/lib/ProhibitIcon';
import SignOutIcon from 'phosphor-svelte/lib/SignOutIcon';
import SunIcon from 'phosphor-svelte/lib/SunIcon';
import TShirtIcon from 'phosphor-svelte/lib/TShirtIcon';
import UserIcon from 'phosphor-svelte/lib/UserIcon';
import UsersIcon from 'phosphor-svelte/lib/UsersIcon';
import WarningIcon from 'phosphor-svelte/lib/WarningIcon';
import WrenchIcon from 'phosphor-svelte/lib/WrenchIcon';
import type { Action, Scope } from './types';

export type Icon = typeof UserIcon;

const byName: Record<string, Icon> = {
  reviveSelf: HeartIcon,
  revive: HeartIcon,
  reviveAll: HeartIcon,
  reviveRadius: HeartIcon,
  teleportMarker: MapPinIcon,
  teleportCoords: MapPinIcon,
  teleportLocation: MapPinIcon,
  teleportBack: ArrowUUpLeftIcon,
  copyVector2: CopyIcon,
  copyVector3: CopyIcon,
  copyVector4: CopyIcon,
  copyHeading: CopyIcon,
  copyEntity: CopyIcon,
  fixVehicle: WrenchIcon,
  fixTheirVehicle: WrenchIcon,
  refuelVehicle: GasPumpIcon,
  giveItem: CubeIcon,
  giveItemAll: UsersIcon,
  giveMoney: MoneyIcon,
  giveMoneyAll: MoneyIcon,
  removeMoney: MoneyIcon,
  giveCar: CarIcon,
  clothing: TShirtIcon,
  goto: NavigationArrowIcon,
  bring: ArrowLineDownIcon,
  spectate: EyeIcon,
  warn: WarningIcon,
  kick: SignOutIcon,
  kickAll: SignOutIcon,
  ban: ProhibitIcon,
  unban: ProhibitIcon,
};

const byScope: Record<Scope, Icon> = {
  self: UserIcon,
  player: UsersIcon,
  vehicle: CarIcon,
  world: SunIcon,
  server: HardDrivesIcon,
  report: FlagIcon,
};

export function actionIcon(action: Action): Icon {
  return byName[action.name] ?? byScope[action.scope];
}
