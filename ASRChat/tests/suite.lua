local A,S=ASRChat,ASRSuite;
ASRSuiteRuntime.scripts.OnEvent(ASRSuiteRuntime,"ADDON_LOADED","ASRSuite"); A.BindSuite();
assert(S.pages.chat and S.panelAdapters.chat and S.compatibilityGroups.chat,"Chat settings, docking and compatibility are registered");
S.SetEditing(true); assert(A.editing and A.frame:GetFrameStrata()=="FULLSCREEN_DIALOG" and A.CanMove());
S.SetEditing(false); assert(not A.editing and A.frame:GetFrameStrata()=="HIGH");
local c=S.pages.chat.chatControls; c.steps.fontSize.plus.scripts.OnClick(); assert(ASRChatDB.fontSize==13 and ChatFrame1.fontSize==13,"Suite setting updates the real native chat");
S.SetLanguage("en"); A.BindSuite(); assert(ASRChatDB.language=="en");
S.SetLanguage("jaJP"); assert(ASRChatDB.language=="jaJP" and ChatFrame1.fontPath=="Fonts\\KOSUGI.TTF","Suite selects Japanese chat font immediately");
S.SetLanguage("en"); assert(ChatFrame1.fontPath~="Fonts\\KOSUGI.TTF","English restores native font");
local code=assert(S.ExportSettings()); local profile=assert(S.DecodeSettings(code)); assert(profile.chat.fontSize==13 and profile.chat.position.x==120 and profile.chat.messages==nil,"profile contains settings and placement, never chat history");
ASRChatDB.fontSize=20; assert(S.ImportSettings(code)); assert(ASRChatDB.fontSize==13);
S.controls.compatibility.chat.panel.scripts.OnClick(); assert(not ASRChatDB.enabled and ChatFrame1.AddMessage==NativeAddMessage,"compatibility switch returns native chat");
print("PASS: Chat Suite settings, editing, profile transfer and restoration");
for _,code in ipairs(ASRLocale.order) do S.SetLanguage(code); A.DrawSettings(); assert(ASRChatDB.language==code); end
S.SetLanguage("en");
