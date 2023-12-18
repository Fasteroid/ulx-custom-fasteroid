if (SERVER) then --the init.lua stuff goes in here
    AddCSLuaFile()
    SWEP.AutoSwitchTo = true
end
 
if (CLIENT) then --the cl_init.lua stuff goes in here
   SWEP.PrintName     = "loading..."
   SWEP.DrawAmmo      = false
   SWEP.DrawCrosshair = true
end

SWEP.Spawnable      = false;
SWEP.AdminSpawnable = false;
SWEP.AdminOnly		= false
SWEP.Category 		= "ULX"
SWEP.IconLetter     = "D"
SWEP.Slot           = 5
SWEP.Purpose        = "Execute ULX commands"
SWEP.Instructions   = "ATK1 -> Execute\nATK2 -> Drop"

SWEP.ViewModel      = "models/weapons/v_pistol.mdl"
SWEP.WorldModel     = "models/weapons/w_pistol.mdl"

SWEP.HoldType          = "pistol"
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo      = "none"
SWEP.Secondary.Ammo    = "none"

function SWEP:Initialize() end

function SWEP:Reload() end

function SWEP:PrimaryAttack()
    self.Owner:ViewPunch( Angle( -5,0,0 ) )
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Owner:SetVelocity( VectorRand() * 1000 )
end

function SWEP:SecondaryAttack()    
	if SERVER then
    	self.Owner:DropWeapon(self)
	end
end

baseclass.Set( "swepify_gun", SWEP )
