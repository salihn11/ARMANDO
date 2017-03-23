--[[ 

--]]
kicktable = {}

do

local TIME_CHECK = 2 -- seconds
-- Save stats, ban user
local function pre_process(msg)
  -- Ignore service msg
  if msg.service then
    return msg
  end
  if msg.from.id == our_id then
    return msg
  end
  
    -- Save user on Redis
  if msg.from.type == 'user' then
    local hash = 'user:'..msg.from.id
    print('Saving user', hash)
    if msg.from.print_name then
      redis:hset(hash, 'print_name', msg.from.print_name)
    end
    if msg.from.first_name then
      redis:hset(hash, 'first_name', msg.from.first_name)
    end
    if msg.from.last_name then
      redis:hset(hash, 'last_name', msg.from.last_name)
    end
  end

  -- Save stats on Redis
  if msg.to.type == 'chat' then
    -- User is on chat
    local hash = 'chat:'..msg.to.id..':users'
    redis:sadd(hash, msg.from.id)
  end

  -- Save stats on Redis
  if msg.to.type == 'channel' then
    -- User is on channel
    local hash = 'channel:'..msg.to.id..':users'
    redis:sadd(hash, msg.from.id)
  end
  
  if msg.to.type == 'user' then
    -- User is on chat
    local hash = 'PM:'..msg.from.id
    redis:sadd(hash, msg.from.id)
  end

  -- Total user msgs
  local hash = 'msgs:'..msg.from.id..':'..msg.to.id
  redis:incr(hash)

  --Load moderation data
  local data = load_data(_config.moderation.data)
  if data[tostring(msg.to.id)] then
    --Check if flood is on or off
    if data[tostring(msg.to.id)]['settings']['flood'] == 'no' then
      return msg
    end
  end

  -- Check flood
  if msg.from.type == 'user' then
    local hash = 'user:'..msg.from.id..':msgs'
    local msgs = tonumber(redis:get(hash) or 0)
    local data = load_data(_config.moderation.data)
    local NUM_MSG_MAX = 5
    if data[tostring(msg.to.id)] then
      if data[tostring(msg.to.id)]['settings']['flood_msg_max'] then
        NUM_MSG_MAX = tonumber(data[tostring(msg.to.id)]['settings']['flood_msg_max'])--Obtain group flood sensitivity
      end
    end
    local max_msg = NUM_MSG_MAX * 1
    if msgs > max_msg then
	  local user = msg.from.id
	  local chat = msg.to.id
	  local whitelist = "whitelist"
	  local is_whitelisted = redis:sismember(whitelist, user)
      -- Ignore mods,owner and admins
      if is_momod(msg) then 
        return msg
      end
	  if is_whitelisted == true then
		return msg
	  end
	  local receiver = get_receiver(msg)
	  if msg.to.type == 'user' then
		local max_msg = 7 * 1
		print(msgs)
		if msgs >= max_msg then
			print("Pass2")
      send_large_msg("user#id"..msg.from.id, "⚠️ |  مـمـنـوع الـتـكـرار |🗣 "..msg.from.first_name.."\n⚠️ | بـسـبـب تـكـرار النـشـر |📛\n⚠️ | تم حظرك تلقائيأ \n⚠️ | مـعـرفـك |👥 : @"..(msg.from.username or "لا يوجد " ).."\n⚠️ | الــقــنــاه |🔰 : @lTSHAKEl_CH ")
			savelog(msg.from.id.." PM", "⚠️ |  مـمـنـوع الـتـكـرار |🗣 "..msg.from.first_name.."\n⚠️ | بـسـبـب تـكـرار النـشـر |📛\n⚠️ | تم حظرك تلقائيأ \n⚠️ | مـعـرفـك |👥 : @"..(msg.from.username or "لا يوجد " ).."\n⚠️ | الــقــنــاه |🔰 : @lTSHAKEl_CH ")
			block_user("user#id"..msg.from.id,ok_cb,false)--Block user if spammed in private
		end
      end
	  if kicktable[user] == true then
		return
	  end
	  delete_msg(msg.id, ok_cb, false)
	  kick_user(user, chat)
	  local username = msg.from.username
	  local print_name = user_print_name(msg.from):gsub("‮", "")
	  local name_log = print_name:gsub("_", "")
	  if msg.to.type == 'chat' or msg.to.type == 'channel' then
      if username then 
         savelog(msg.to.id, name_log.." @"..username.." ["..msg.from.id.."] kicked for #spam") 
send_large_msg(receiver , "⚠️ |  مـمـنـوع الـتـكـرار |🗣 "..msg.from.first_name.."\n⚠️ | بـسـبـب تـكـرار النـشـر |📛\n⚠️ | تم حظرك من الـمـجـمـوعـه تلقائيأ \n⚠️ | عـبـر حـمـايـه الــبوت |✔️ \n⚠️ | مـعـرف الــعــضــو |👥 : @"..(msg.from.username or "لا يوجد " ).."\n⚠️ | الــقــنــاه |🔰 : @lTSHAKEl_CH ")
      else 
         savelog(msg.to.id, name_log.." ["..msg.from.id.."] kicked for #spam") 
send_large_msg(receiver , "⚠️ |  مـمـنـوع الـتـكـرار |🗣 "..msg.from.first_name.."\n⚠️ | بـسـبـب تـكـرار النـشـر |📛\n⚠️ | تم حظرك من الـمـجـمـوعـه تلقائيأ \n⚠️ | عـبـر حـمـايـه الــبوت |✔️\n⚠️ | مـعـرف الــعــضــو |👥 : @"..(msg.from.username or "لا يوجد " ).."\n⚠️ | الــقــنــاه |🔰 : @lTSHAKEl_CH ")
      end
     end 
      -- incr it on redis
      local gbanspam = 'gban:spam'..msg.from.id
      redis:incr(gbanspam)
      local gbanspam = 'gban:spam'..msg.from.id
      local gbanspamonredis = redis:get(gbanspam)
      --Check if user has spammed is group more than 4 times  
      if gbanspamonredis then
        if tonumber(gbanspamonredis) ==  4 and not is_owner(msg) then
          --Global ban that user
          banall_user(msg.from.id)
          local gbanspam = 'gban:spam'..msg.from.id
          --reset the counter
          redis:set(gbanspam, 0)
          if msg.from.username ~= nil then
            username = msg.from.username
		  else 
			username = "---"
          end
          local print_name = user_print_name(msg.from):gsub("‮", "")
		  local name = print_name:gsub("_", "")
          --Send this to that chat
          send_large_msg("chat#id"..msg.to.id, "User [ "..name.." ]"..msg.from.id.." globally banned (spamming)")
		  send_large_msg("channel#id"..msg.to.id, "User [ "..name.." ]"..msg.from.id.." globally banned (spamming)")
          local GBan_log = 'GBan_log'
		  local GBan_log =  data[tostring(GBan_log)]
		  for k,v in pairs(GBan_log) do
			log_SuperGroup = v
			gban_text = "User [ "..name.." ] ( @"..username.." )"..msg.from.id.." Globally banned from ( "..msg.to.print_name.." ) [ "..msg.to.id.." ] (spamming)"
			--send it to log group/channel
			send_large_msg(log_SuperGroup, gban_text)
		  end
        end
      end
      kicktable[user] = true
      msg = nil
    end
    redis:setex(hash, TIME_CHECK, msgs+1)
  end
  return msg
end

local function cron()
  --clear that table on the top of the plugins
	kicktable = {}
end

return {
  patterns = {},
  cron = cron,
  pre_process = pre_process
}

end
__    Dev @Aram_omar22
     |_||___/_| |_/_/   \_\_|\_\_____|   Dev @IXX_I_XXI
              CH > @lTSHAKEl_CH
--]]
do
function run(msg, matches)
 if matches[1] == "الاوامر" and is_momod(msg) then
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
⏺ اهلا بكم هناك 5 اوامر في البوت
|❗️| -------------------------- |❗️|

|📍| م1 | لعرض اوامر الادمنيه و المدير🎐

|📍| م2 | لعرض اوامر الميديا🎐

|📍| م3 | لعرض اوامر حماية 🎐

|📍| م4 | لعرض اوامر بالتحذير🎐

|📍| م5 | لعرض اوامر المجموعه 🎐

|📍| م6 | لعرض اوامر المطورين 🎐
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @salih_n11 '..'\n'
------------------

  elseif matches[1] == "م1" and is_momod(msg) then
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
🔰 اوامر تـخص الادمنيـه و المـديـر 🔰
|❗️| -------------------------- |❗️|

|📍| رفع ادمن
|🎐| لرفع ادمن رد + معرف
|📍| تنزيل ادمن
|🎐| لرفع ادمن رد + معرف

|📍| رفع اداري
|🎐| لرفع اداري رد + معرف
|📍| تنزيل اداري
|🎐| لرفع اداري رد + معرف

|📍| حظر
|🎐| حظر عضو من المجموعه
|📍| الغاء حظر
|🎐| الغاء الحظر عن عضو

|📍| منع + الكلمه
|🎐| منع كلمه  
|📍| الغاء منع + الكلمه
|🎐| الغاء منع كلمه 

|📍| قائمه المنع
|🎐| اظهار الكلمات الممنوعه
|📍| تنظيف قائمه المنع
|🎐| لمسح كل قائمه المنع

|📍| ايدي
|🎐| عرض ايدي المجموعه
|📍| ايدي بالرد
|🎐| عرض ايدي شخص 

|📍| كتم
|🎐| لكتم عضو رد + معرف + ايدي
|📍| المكتومين
|🎐| لعرض قائمه المكتومين

|📍| ضع ترحيب
|🎐| لوضع ترحيب للمجموعه
|📍| حذف الترحيب
|🎐| لحذف الترحيب للمجموعه
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @lTSHAKEl_CH '..'\n'
------------------


  elseif  matches[1] == "م2" and is_momod(msg) then 
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
 ✔️ اوامـر قــفـل و فــتـح الــميديـا ✔️
|❗️| -------------------------- |❗️|
قفل + الامر / للقفل ☑️
فتح + الامر / للفتح  ⚠️
|❗️| -------------------------- |❗️|

|📍| الصوت |🔊
|📍| الصور |🌠
|📍| الفيديو |🎥
|📍| المتحركه |🃏
|📍| الفايلات |🗂
|📍| الدردشه |📇
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @lTSHAKEl_CH '..'\n'
------------------

  elseif  matches[1] == "م3" and is_momod(msg) then 
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
📛اوامـــر حمـــايه الـــمجمـــوعه📛
|❗️| -------------------------- |❗️|
قفل + الامر / للقفل ☑️
فتح + الامر / للفتح  ⚠️
|❗️| -------------------------- |❗️|

|📍| الانلاين |📡
|📍| الكلايش |🚸
|📍| التكرار |🔖
|📍| الطرد |📛

|📍| العربيه |🆎
|📍| الجهات |📩
|📍| المعرف |🌀
|📍| التاك |📥
|📍| الشارحه |〰

|📍| الاضافه |👥
|📍| الروابط |♻️
|📍| البوتات |✳️
|📍| السمايل |😃
|📍| الملصقات |🔐

|📍| الاشعارات |🎌
|📍| اعاده توجيه |↪️
|📍| الدخول |📍
|📍| الجماعيه |❗️
|📍| التعديل |🔏
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @lTSHAKEl_CH '..'\n'
------------------

  elseif  matches[1] == "م4" and is_momod(msg) then 
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
✔️ اوامـر قــفـل و فتـح بالتـحـذيـر ✔️
|❗️| -------------------------- |❗️|
قفل + الامر / للقفل ☑️
فتح + الامر / للفتح  ⚠️
|❗️| -------------------------- |❗️|

|📍| الروابط بالتحذير |♻️
|📍| التوجيه بالتحذير |↪️
|📍| الصور بالتحذير |🌠
|📍| الصوت بالتحذير |🔊

|📍| الفيديو بالتحذير |🎥
|📍| الدردشه بالتحذير |📇
|📍| المعرف بالتحذير |🌀
|📍| الشارحه بالتحذير |〰

|📍| الانلاين بالتحذير |📡
|📍| التاك بالتحذير |📥
|📍| السمايل بالتحذير |😃
|📍| الميديا بالتحذير |📬
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @lTSHAKEl_CH '..'\n'

------------------------

 elseif  matches[1] == "م5" and is_momod(msg) then 
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
🔹- اوامــر تــخــص  المـجـمـوعـه 👁‍🗨
|❗️| -------------------------- |❗️|

|📍| ضع صوره
|🎐| لوضع صوره 
|📍| ضع قوانين
|🎐| لوضع قوانين 

|📍| ضع وصف
|🎐| لوضع وصف  
|📍| ضع اسم
|🎐| لوضع اسم  

|📍| ضع  معرف
|🎐| لوضع معرف 
|📍| ضع رابط
|🎐| لخزن رابط المجموعه

|📍| الرابط
|🎐| لعرض رابط المجموعه 
|📍| معلوماتي
|🎐| لعرض معلوماتك

|📍| معلومات المجموعه
|🎐| لعرض معلومات المجموعه
|📍| اعدادت الوسائط
|🎐| لاضهار الاعدادات الوسائط
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @lTSHAKEl_CH '..'\n'
-----------------------

 elseif  matches[1] == "م6" and is_sudo(msg) then 
    return "اهلا وسهلا بك 😻🎈 "..msg.from.first_name.."\n"
  .."  ".."\n"
  ..[[
  🔧 اوامـــر المــطـــوريـــن  ⚙
|❗️| -------------------------- |❗️|

|📍| تفعيل البوت 
|🎐| لتفعيل البوت بالمجموعه 
|📍|  تعطيل البوت
|🎐| لتعطيل البوت بالمجموعه 

|📍| رفع المدير 
|🎐| لرفع المدير عن طريق الرد + معرف  
|📍| وضع وقت + عدد الايام
|🎐| لتفعيل البوت ع عدد الايام

|📍| الوقت
|🎐| لمعرفت عدد ايام تفعيل البوت
|📍| اذاعه 
|🎐| لنشر شئ بكل مجموعات البوت 

|📍| زحلك 
|🎐| لطرد البوت من المجموعه 
|📍| جلب ملف + اسم الملف    
|🎐| لجلب ملف من سيرفر البوت 

|📍| تفعيل + اسم الملف 
|🎐| لتفعيل ملف عن طريق البوت
|📍| تعطيل + اسم للملف
|🎐| لتعطيل ملف عن طريق البوت

|📍| صنع مجموعه + الاسم 
|🎐| لصنع مجموعه بواسطه البوت
|📍| ترقيه سوبر  
|🎐| لترقيه المجموعه بواسطه البوت
]].."\n"
.."|❗️| -------------------------- |❗️|".."\n"
..'|❗️| CH | @salih_n '..'\n'
------------------
  end
end
return {
  patterns = {
    "^(الاوامر)",
    "^(م1)",
    "^(م2)",
    "^(م3)",
    "^(م4)",
    "^(م5)",
    "^(م6)",
    "^[#!/](الاوامر)",
    "^[#!/](م1)",
    "^[#!/](م2)",
    "^[#!/](م3)",
    "^[#!/](م4)",
    "^[#!/](م5)",
    "^[#!/](م6)"
  },
  run = run
}
end


--[[ 
    _____    _        _    _    _____    Dev @lIMyIl 
   |_   _|__| |__    / \  | | _| ____|   Dev @li_XxX_il
     | |/ __| '_ \  / _ \ | |/ /  _|     Dev @h_k_a
     | |\__ \ | | |/ ___ \|   <| |___    Dev @Aram_omar22
     |_||___/_| |_/_/   \_\_|\_\_____|   Dev @IXX_I_XXI
              CH > @lTSHAKEl_CH
--]]
