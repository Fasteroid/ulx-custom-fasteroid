if (SERVER) then --the init.lua stuff goes in here
    AddCSLuaFile()
    SWEP.AutoSwitchTo = true
end
 
if (CLIENT) then --the cl_init.lua stuff goes in here
   SWEP.PrintName     = "swepify loading..."
   SWEP.DrawAmmo      = false
   SWEP.DrawCrosshair = true
end

SWEPIFY = {}

SWEPIFY.unused = {}
SWEPIFY.next   = 0

SWEPIFY.reset = function()
	for _, gun in ipairs( ents.FindByClass("swepify_gun_*") ) do
		gun:Remove()
	end
	timer.Simple(0.1,function()
		SWEPIFY.unused = {}
		SWEPIFY.next   = 0
	end)
end
SWEPIFY.reset()

SWEPIFY.allocate = function()
	local unused = SWEPIFY.unused
	if CLIENT then Error("don't call this on client dumbass") end
	if #SWEPIFY.unused > 0 then 
		local ret = unused[#unused]
		unused[#unused] = nil
		return ret
	else
		SWEPIFY.next = SWEPIFY.next + 1
		return SWEPIFY.next
	end
end

SWEPIFY.free = function(id)
	if CLIENT then Error("don't call this on client dumbass") end
	local unused = SWEPIFY.unused
	unused[#unused+1] = id
end

SWEPIFY.generate = function(id)
	if id == nil then id = SWEPIFY.allocate() end

	local SWEP = {}
	SWEP.Base = "swepify_gun"
	SWEP.SwepID = id
	SWEP.ClassName = "swepify_gun_" .. id

	return SWEP
end


SWEP.Spawnable      = false;
SWEP.AdminSpawnable = false;
SWEP.AdminOnly		= false
SWEP.Category 		= "ULX"
SWEP.IconLetter     = "D"
SWEP.Slot           = 5
SWEP.Author         = "(Console)"
SWEP.Instructions   = "Left mouse to execute ULX command, right mouse to drop."

SWEP.ViewModel      = "models/weapons/c_pistol.mdl"
SWEP.WorldModel     = "models/weapons/w_pistol.mdl"

SWEP.HoldType           = "pistol"
SWEP.Primary.Automatic  = false
SWEP.Primary.Ammo       = "none"
SWEP.Primary.ClipSize   = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.ClipSize = -1

SWEP.UseHands     = true
SWEP.AuthorEntity = nil   -- server only

function SWEP:SetupDataTables()
	self:NetworkVar("String", 0, "SwepAuthor")
	self:NetworkVar("String", 1, "SwepName")
	self:NetworkVar("Int",0, "SwepID")
end

function SWEP:OnRemove()
	if SERVER then SWEPIFY.free(self.SwepID) end
	weapons.Register({Base = "swepify_gun"}, self.ClassName)
end

function SWEP:Initialize()
	if SERVER then
		hook.Add("Think", self.Weapon, function()
			if self.AuthorEntity and not self.AuthorEntity:IsValid() then
				local effectdata = EffectData()
				effectdata:SetOrigin( self.Weapon:GetPos() )
				util.Effect( "HelicopterMegaBomb", effectdata )
				self:Remove()
			end
		end)
	end
	if CLIENT then
		self.Author    = self:GetSwepAuthor()
		self.PrintName = self:GetSwepName()
		self.SwepID    = self:GetSwepID()
	end
end

function SWEP:PrimaryAttack()
	self.Owner = self:GetOwner()
    self.Owner:ViewPunch( Angle( -1,0,0 ) )
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
	if SERVER then 
		self.Owner:EmitSound("AlyxEMP.Discharge") 
	end
	local effectdata = EffectData()
	effectdata:SetOrigin( self.Owner:GetEyeTraceNoCursor().HitPos )
	effectdata:SetStart( self.Owner:GetShootPos() )
	effectdata:SetAttachment( 1 )
	effectdata:SetEntity( self.Weapon )
	effectdata:SetMagnitude( 1 )
	util.Effect( "ToolTracer", effectdata )
end

function SWEP:SecondaryAttack()    
	if SERVER then
    	self.Owner:DropWeapon(self)
	end
end

if CLIENT then
	local this = table.Copy(SWEP)
	hook.Add("OnEntityCreated","ULX.Fasteroid.SwepifyDownload",function(e)
		if(e:GetClass():StartsWith("swepify_gun")) then
			weapons.Register(this, e:GetClass())
		end
	end)
end