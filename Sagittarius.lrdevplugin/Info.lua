--[[----------------------------------------------------------------------------

Info.lua
Summary information

------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 4.0,
	LrToolkitIdentifier = 'net.azurewebsites.qiu.astrology.sagittarius',
	LrPluginName = LOC "$$$/US_EN/PluginName=Sagittarius",
	LrPluginInfoUrl = "http://qiu.azurewebsites.net/Sparrow/Astrology?name=Sagittarius",

	LrInitPlugin = 'SagittariusBackground.lua',
	LrForceInitPlugin = true,

	LrLibraryMenuItems = {
		title = 'Run Sagittarius',
		file = 'SagittariusBackground.lua',
	},

	VERSION = { major=1, minor=0, revision=0, build=1200, },

}