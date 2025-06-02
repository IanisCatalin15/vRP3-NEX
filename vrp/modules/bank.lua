-- Improved Money Module for vRP3
-- MIT license (see LICENSE or vrp/vRPShared.lua)
if not vRP.modules.bank then return end

local Bank = class("Bank", vRP.Extension)
Bank.User = class("User")  

-- Transfer funds from sender’s bank to target’s bank.
function Bank.User:transfer(target, amount)
  if type(amount) ~= "number" or amount <= 0 then
    return false, "Invalid amount"
  end

  if not target or type(target.addBank) ~= "function" then
    return false, "Invalid target"
  end

  -- Attempt to deduct funds first
  if self:tryCardPayment(amount, false) then
    local success, err = pcall(function()
      target:addBank(amount)

      -- Trigger update events
      vRP:triggerEvent("playerMoneyUpdate", self)
      vRP:triggerEvent("playerMoneyUpdate", target)

      -- Save both users
      self:save()
      target:save()
    end)

    if success then
      return true
    else
      -- Rollback: refund the sender if something failed
      self:addBank(amount)
      self:save()
      return false, "Transfer failed: " .. tostring(err)
    end
  else
    return false, "Not enough bank funds"
  end
end


-------------------------------------------------------------------
-- Module Initialization & Menus
-------------------------------------------------------------------

function Bank:__construct()
  vRP.Extension.__construct(self)
  self.cfg = module("cfg/bank")
  self:log(#self.cfg.banks.." Banks")
  self:log(#self.cfg.atms.." Atms")

  -- Menu option: Show account info
  local function m_account_info(menu, index)
    local user = menu.user
    local bank_balance = user:getBank()
    menu:updateOption(index, nil, string.format("<br> Bank Balance: %s", formatNumber(bank_balance)))
  end

  -- Menu option: Deposit money
  local function m_deposit(menu)
    local user = menu.user
    local input = user:prompt("Enter amount to deposit:", "")
    local amount = tonumber(input) or 0
    local user_money = user:getWallet()

    if amount <= 0 then
      vRP.EXT.Base.remote._notify(user.source, "Invalid amount")
      return
    end

    if user_money < amount then
      vRP.EXT.Base.remote._notify(user.source, "You don't have enough cash!")
      return
    end

    local success, err = user:tryDeposit(amount)
    if success then
      vRP.EXT.Base.remote._notify(user.source, "Deposited $" .. formatNumber(amount))
    else
      vRP.EXT.Base.remote._notify(user.source, "Deposit failed: " .. (err or "unknown error"))
    end
  end

  -- Menu option: Withdraw (for bank and ATM)
  local function m_withdraw(menu)
    local user = menu.user
    local input = user:prompt("Enter amount to withdraw:", "")
    local amount = tonumber(input)
    local user_bank = user:getBank()

    if not amount or amount <= 0 then
      vRP.EXT.Base.remote._notify(user.source, "Invalid amount")
      return
    end

    amount = math.floor(amount)
    local max_limit = 100000

    if amount > max_limit then
      vRP.EXT.Base.remote._notify(user.source, "Maximum withdrawal is $" .. formatNumber(max_limit))
      return
    end

    if user_bank < amount then
      vRP.EXT.Base.remote._notify(user.source, "Insufficient bank balance!")
      return
    end

    local success, err = user:tryWithdraw(amount)
    if success then
      vRP.EXT.Base.remote._notify(user.source, "Withdrew $" .. formatNumber(amount))
    else
      vRP.EXT.Base.remote._notify(user.source, "Withdrawal failed: " .. (err or "unknown error"))
    end
  end

  -- Menu option: Transfer funds to another user
  local function m_transfer(menu)
    local user = menu.user

    local target_id = tonumber(user:prompt("Enter target user ID:", ""))
    if not target_id or target_id <= 0 then
      vRP.EXT.Base.remote._notify(user.source, "Invalid target user ID")
      return
    end

    if target_id == user.id then
      vRP.EXT.Base.remote._notify(user.source, "You cannot transfer money to yourself")
      return
    end

    local amount = tonumber(user:prompt("Enter amount to transfer:", ""))
    if not amount or amount <= 0 then
      vRP.EXT.Base.remote._notify(user.source, "Invalid amount")
      return
    end

    amount = math.floor(amount)
    local user_wallet = user:getBank()

    if user_wallet < amount then
      vRP.EXT.Base.remote._notify(user.source,
        "You don't have enough money to transfer!")
      return
    end

    local target = vRP.users[target_id]
    if not target then
      vRP.EXT.Base.remote._notify(user.source, "Target user not found")
      return
    end

    local success, err = user:transfer(target, amount)
    if success then
      vRP.EXT.Base.remote._notify(user.source, "Transferred $" .. formatNumber(amount) .. " to user " .. target_id)
      vRP.EXT.Base.remote._notify(target.source, "Received $" .. formatNumber(amount) .. " from user " .. user.id)
    else
      vRP.EXT.Base.remote._notify(user.source, "Transfer failed: " .. (err or "unknown error"))
    end
  end
  
  -- Register bank menu
  vRP.EXT.GUI:registerMenuBuilder("bank", function(menu)
    local user = vRP.users_by_source[menu.user.source]
    local character_id = user.cid

    if character_id then
      menu.title = "Bank"
      menu.css = { top = "75px", header_color = "rgba(200,0,0,0.75)" }

      menu:addOption("Account Info", m_account_info, "") -- index will be passed to update later
      menu:addOption("Deposit", m_deposit, "Deposit money into bank")
      menu:addOption("Withdraw", m_withdraw, "Withdraw money from bank")
      menu:addOption("Transfer", m_transfer, "Transfer money to another account")
    end
  end)

  -- Register ATM menu
  vRP.EXT.GUI:registerMenuBuilder("atm", function(menu)
    local user = vRP.users_by_source[menu.user.source]
    local character_id = user.cid

    if character_id then
      menu.title = "ATM"
      menu.css = { top = "75px", header_color = "rgba(0,200,0,0.75)" }

      menu:addOption("Account Info", m_account_info, "") -- will auto-update inside handler
      menu:addOption("Withdraw", m_withdraw, "Withdraw money from bank")
      menu:addOption("Transfer", m_transfer, "Transfer money to another account")
    end
  end)
end

Bank.event = {}
function Bank.event:playerSpawn(user, first_spawn)
    if first_spawn then 
      local menu
      local function enter_atm(user)
        menu = user:openMenu("atm")
      end

      local function leave(user)
        user:closeMenu(menu)
      end

      local function enter_bank(user)
        menu = user:openMenu("bank")
      end

      for k,v in pairs(self.cfg.atms) do
        local x,y,z = table.unpack(v)

        local atm_ment = clone(self.cfg.atm_map_entity)
        atm_ment[2].title = "ATM"
        atm_ment[2].pos = {x,y,z - 1}
        vRP.EXT.Map.remote._addEntity(user.source,atm_ment[1],atm_ment[2])

        user:setArea("vRP:atm:"..k,x,y,z,0.7,1.5,enter_atm,leave)
      end

      for k,v in pairs(self.cfg.banks) do
        local bx,by,bz = table.unpack(v)

        local ment = clone(self.cfg.bank_map_entity)
        ment[2].title ="Banking"
        ment[2].pos = {bx,by,bz}
        vRP.EXT.Map.remote._addEntity(user.source,ment[1],ment[2])

        user:setArea("vRP:bank:"..k,bx,by,bz,0.7,1.5,enter_bank,leave)
      end
    end
  end

vRP:registerExtension(Bank)
