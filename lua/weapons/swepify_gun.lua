if (SERVER) then --the init.lua stuff goes in here
    AddCSLuaFile()
    SWEP.AutoSwitchTo = true
end
 
if (CLIENT) then --the cl_init.lua stuff goes in here
   SWEP.PrintName     = "ulx swepify"
   SWEP.DrawAmmo      = false
   SWEP.DrawCrosshair = true
end

SWEP.Spawnable      = false;
SWEP.AdminSpawnable = false;
SWEP.AdminOnly		= false
SWEP.Category 		= "ULX"
SWEP.IconLetter     = "D"
SWEP.Slot           = 5
SWEP.Author         = "(Console)"
SWEP.Instructions   = "Left mouse to execute ULX command, right mouse to drop."

SWEP.ViewModel      = "models/weapons/v_pistol.mdl"
SWEP.WorldModel     = "models/weapons/w_pistol.mdl"

SWEP.HoldType          = "pistol"
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo      = "none"
SWEP.Primary.ClipSize  = -1
SWEP.Secondary.Ammo    = "none"
SWEP.Secondary.ClipSize  = -1

function SWEP:Initialize() end

function SWEP:Reload() end

function SWEP:PrimaryAttack()
    self.Owner:ViewPunch( Angle( -1,0,0 ) )
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "SwepAuthor")
	self:NetworkVar("String", 1, "SwepName")

	if CLIENT then
		self:NetworkVarNotify( "SwepAuthor", function(_, _, _, dat) self.Author = dat end )
		self:NetworkVarNotify( "SwepName", function(_, _, _, dat) self.PrintName = dat end )
	end
end

function SWEP:SecondaryAttack()    
	if SERVER then
    	self.Owner:DropWeapon(self)
	end
end
