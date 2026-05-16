local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vezt | Bubble Gum",
   LoadingTitle = "VeztPur Suite",
   LoadingSubtitle = "by VeztWare",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "VeztBubbleGumHolder",
      FileName = "VeztBubbleGum"
   },
   Discord = {
      Enabled = false,
      Value = ""
   },
   KeySystem = false
})


local InfoTab   = Window:CreateTab("Info", 4483362458)       
local MainTab   = Window:CreateTab("Farming", 4483345998)    
local SummerTab = Window:CreateTab("Summer Event", 10734950201) 
local ShopTab   = Window:CreateTab("Eggs & Shops", 4370335091)  


InfoTab:CreateSection("Game: Bubble Gum || " .. game.PlaceId)
local FarmingSection = MainTab:CreateSection("Bubble & Pickup Automation")
local SummerSection  = SummerTab:CreateSection("Artifact Activities")
local EggSection     = ShopTab:CreateSection("Egg Hatching Setup")
local ShopSection    = ShopTab:CreateSection("Merchant Automation")


local player = game.Players.LocalPlayer
local lplr = player
local character = player.Character
local hrp = character and character:FindFirstChild("HumanoidRootPart")
local sharedEvent = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent")
local PickupRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Pickups"):WaitForChild("CollectPickup")

local ChestsDB = require(game:GetService("ReplicatedStorage").Shared.Data.Chests)
local Eggs = require(game:GetService("ReplicatedStorage").Shared.Data.Eggs)
local MetalDetectorPath = game:GetService("ReplicatedStorage"):WaitForChild("Client"):WaitForChild("Gui"):WaitForChild("Frames"):WaitForChild("SummerEvent"):WaitForChild("MetalDetector")
local MetalDetectorModule = require(MetalDetectorPath:WaitForChild("Input"))
local LocalArtifactManager = require(MetalDetectorPath:WaitForChild("LocalArtifactManager"))
local MultiplayerArtifactManager = require(MetalDetectorPath:WaitForChild("MultiplayerArtifactManager"))


local EggList = {}
for eggName, eggData in pairs(Eggs) do
    if eggData.Cost and eggData.Cost["Type"] == "Currency" then
        table.insert(EggList, eggName)
    end
end

table.sort(EggList) 

for _, connection in pairs(getconnections(lplr.Idled)) do
    if connection["Disable"] then
        connection["Disable"](connection)
    elseif connection["Disconnect"] then
        connection["Disconnect"](connection)
    end
end

getgenv().SelectedEgg = EggList[1] or "Common Egg" 
getgenv().AutoBubble = false
getgenv().AutoSell = false
getgenv().AutoPickup = false
getgenv().AutoArtifact = false
getgenv().AutoSellArtifacts = false
getgenv().AutoPlayTime = false
getgenv().AutoHatchEgg = false
getgenv().AutoAlienShop = false
getgenv().AutoDiceShop = false


player.CharacterAdded:Connect(function(char)
    character = char
    hrp = char:WaitForChild("HumanoidRootPart")
end)


function GetPickUpChunk()
    for i, v in pairs(workspace.Rendered:GetChildren()) do
        if v.Name == "Chunker" then
            local model = v:FindFirstChildWhichIsA("Model")
            if model and string.find(model.Name, "-") then
                return v
            end
        end
    end
    return nil
end

function BuyFromAlienShop(shelf, amount)
    for i = 1, amount do
        task.wait(0.5)
        local args = { "BuyShopItem", "alien-shop", shelf }
        sharedEvent:FireServer(unpack(args))
    end
end       

function BuyFromDiceShop(shelf, amount)
    for i = 1, amount do
        task.wait(0.5)
        local args = { "BuyShopItem", "dice-shop", shelf }
        sharedEvent:FireServer(unpack(args))
    end
end      

function ActionAlienShop()
    for i = 1, 3 do BuyFromAlienShop(tonumber(i), 15) end
end

function ActionDiceShop()
    for i = 1, 3 do BuyFromDiceShop(tonumber(i), 15) end
end

function GetNearestPickup()
    local chunk = GetPickUpChunk()
    if not hrp or not chunk then return nil end
    local nearest, shortestDistance = nil, 100

    for _, item in pairs(chunk:GetChildren()) do
        local dist = (hrp.Position - item.WorldPivot.Position).Magnitude
        if dist < shortestDistance then
            nearest = item
            shortestDistance = dist
        end
    end
    return nearest
end

function GetNearestArtifactPosition()
    if not hrp then return nil end
    local myPos = hrp.Position

    local localArtifacts = LocalArtifactManager:GetActiveArtifacts() or {}
    local multiArtifacts = MultiplayerArtifactManager:GetActiveArtifacts() or {}
    local closestPos = nil
    local shortestDistance = math.huge

    local function scanTable(artifactTable)
        for _, artifact in pairs(artifactTable) do
            local artPos = artifact._position or (artifact._instance and artifact._instance.Position)
            if not artPos and type(artifact) == "table" then
                for _, val in pairs(artifact) do
                    if typeof(val) == "Vector3" then artPos = val break end
                end
            end

            if artPos then
                local distance = (myPos - artPos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPos = artPos
                end
            end
        end
    end

    scanTable(localArtifacts)
    scanTable(multiArtifacts)
    return closestPos
end




MainTab:CreateToggle({
   Name = "Auto Bubble",
   CurrentValue = false,
   Flag = "AutoBubbleFlag",
   Callback = function(Value)
      getgenv().AutoBubble = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoBubble and task.wait() do
                  sharedEvent:FireServer("BlowBubble")
              end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Sell Bubbles",
   CurrentValue = false,
   Flag = "AutoSellFlag",
   Callback = function(Value)
      getgenv().AutoSell = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoSell and task.wait() do
                  sharedEvent:FireServer("SellBubble")
              end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Pickup",
   CurrentValue = false,
   Flag = "AutoPickupFlag",
   Callback = function(Value)
      getgenv().AutoPickup = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoPickup and task.wait(0.25) do
                  local item = GetNearestPickup()
                  if item then
                      PickupRemote:FireServer(item.Name)
                      item:Destroy()
                  end
              end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Claim Playtime",
   CurrentValue = false,
   Flag = "AutoPlayTimeFlag",
   Callback = function(Value)
      getgenv().AutoPlayTime = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoPlayTime and task.wait(10) do
                  for i = 1, 9 do
                      local args = { [1] = "ClaimPlaytime", [2] = i }
                      game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))    
                  end            
              end
          end)
      end
   end,
})




SummerTab:CreateToggle({
   Name = "Auto Artifact (Walk + Dig)",
   CurrentValue = false,
   Flag = "AutoArtifactFlag",
   Callback = function(Value)
      getgenv().AutoArtifact = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoArtifact do
                  task.wait(0.1)
                  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                  if humanoid and humanoid.Health > 0 then
                      local targetPos = GetNearestArtifactPosition()
                      if targetPos then humanoid:MoveTo(targetPos) end
                  end
              end
          end)

          task.spawn(function()
              while getgenv().AutoArtifact do
                  pcall(function() MetalDetectorModule:Dig() end)
                  local currentSpeed = 0.05
                  pcall(function() currentSpeed = MetalDetectorModule:GetCurrentDigSpeed() or 0.05 end)
                  task.wait(currentSpeed)
              end
          end)
      end
   end,
})

SummerTab:CreateToggle({
   Name = "Auto Sell Artifacts",
   CurrentValue = false,
   Flag = "AutoSellArtifactsFlag",
   Callback = function(Value)
      getgenv().AutoSellArtifacts = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoSellArtifacts and task.wait(0.1) do
                  local args = { "SellArtifacts" }
                  game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
              end
          end)
      end
   end,
})




ShopTab:CreateDropdown({
   Name = "Select Target Egg",
   Options = EggList,
   CurrentOption = {EggList[1] or "Common Egg"},
   MultipleOptions = false,
   Flag = "EggSelectorFlag",
   Callback = function(Selected)
      getgenv().SelectedEgg = Selected[1]
   end,
})

ShopTab:CreateToggle({
   Name = "Auto Hatch Selection",
   CurrentValue = false,
   Flag = "AutoHatchEggFlag",
   Callback = function(Value)
      getgenv().AutoHatchEgg = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoHatchEgg and task.wait(0.1) do
                  local args = {
                      "HatchEgg",
                      getgenv().SelectedEgg,
                      99
                  }
                  game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))                
              end
          end)
      end
   end,
})

ShopTab:CreateToggle({
   Name = "Auto Buy Alien Merchant",
   CurrentValue = false,
   Flag = "AutoAlienShopFlag",
   Callback = function(Value)
      getgenv().AutoAlienShop = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoAlienShop do
                  ActionAlienShop()
                  task.wait(20)
              end
          end)
      end
   end,
})

ShopTab:CreateToggle({
   Name = "Auto Buy Dice Merchant",
   CurrentValue = false,
   Flag = "AutoDiceShopFlag",
   Callback = function(Value)
      getgenv().AutoDiceShop = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoDiceShop do
                  ActionDiceShop()
                  task.wait(20)
              end
          end)
      end
   end,
})


ShopTab:CreateToggle({
   Name = "Auto Claim All Chests",
   CurrentValue = false,
   Flag = "AutoClaimChestsFlag",
   Callback = function(Value)
      getgenv().AutoClaimChests = Value
      if Value then
          task.spawn(function()
              while getgenv().AutoClaimChests do
                  for i,v in pairs(ChestsDB) do
                    local args = {
                    	"ClaimChest",
                    	i,
                    	true
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                    task.wait(1)
                end
                task.wait(10)
              end
          end)
      end
   end,
})
