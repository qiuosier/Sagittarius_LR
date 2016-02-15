-- Static Variables
LOG_FILENAME = "libraryLogger"
KML_DATA_FOLDER = [[C:\Qiu\Library\Astrology\Sagittarius Lightroom\LocationData\]]
PROCESSED_FILE_LIST = _PLUGIN.path .. [[\ProcessedFiles.txt]]
GPS_DATA_FOLDER = _PLUGIN.path .. [[\GPSData\]]
CAMERA_TIME_ZONE = 4

-- Log File
local LrLogger = import 'LrLogger'
local myLogger = LrLogger( LOG_FILENAME )
myLogger:enable( "logfile" )

function OutputToLog( message )
	myLogger:trace( message )
end

-- Validate File
function ValidateKML( filePath )
	local file = io.open(filePath, "r")
	if file == nil then return false end
	for i = 1, 3 do
		local line = ""
		while string.len(line) == 0 do
			line = file:read("*line")
		end
		if string.find(string.upper(line), "<KML") then
			OutputToLog("File is Validated")
			return true
		end
	end
	file:close()
	return false
end

-- Scan Directory
function ScanGPSFiles( directory )
    local i, t, popen = 0, {}, io.popen
    for fileEntry in popen('dir "'..directory..'"'):lines() do
    	if (not string.find(fileEntry, "<DIR>")) then
    		i = i + 1
        	t[i] = fileEntry
        end
    end
    -- Remove the last 2 and the first 5 entries (summary)
    table.remove(t, i)
    table.remove(t, i - 1)
    for k = 1, 5 do
    	table.remove(t, 1)
    end
    return t
end

-- Get Filename
function GetFileName( dirOutput )
	local x = string.find(dirOutput, "%s[^%s]*$")
	return string.sub(dirOutput, x + 1, -1)
end

-- Check processed file
function CheckProcessedFiles( fileEntry )
	-- Load processed file list
	local file = io.open(PROCESSED_FILE_LIST, "r")
	if file == nil then return false end
	local line = file:read()
	while line do
		if fileEntry == line then 
			return true 
		end
		line = file:read()
	end
	file:close()
	return false
end

-- Add file to processed file list
function AddProcessedFile( fileEntry )
	local file = io.open(PROCESSED_FILE_LIST, "a")
	if file == nil then
		file = io.open(PROCESSED_FILE_LIST, "w")
	end
	file:write(fileEntry .. "\n")
	file:close()
end

-- Trim String
function TrimString(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Get Date and Time
function GetDateTime( kmlWhenTag )
	kmlWhenTag = TrimString(kmlWhenTag)
	local utcDateTime = string.gsub(kmlWhenTag, "<when>", "")
	utcDateTime = string.gsub(utcDateTime, "</when>", "")
	utcDate = string.sub(utcDateTime, 1, 10)
	utcTime = string.sub(utcDateTime, 12, -2)
	return utcDate, utcTime
end

-- Process KML files
function ProcessGPSFile( fileEntry )
	-- Check if file is already been processed
	if not CheckProcessedFiles(fileEntry) then
		local filename = GetFileName(fileEntry)
		local filePath = KML_DATA_FOLDER .. filename
		-- Check if the file is validate
		if ValidateKML(filePath) then
			local file = io.open(filePath, "r")
			if file == nil then return false end
			-- Process the file
			local indexFile = nil
			local indexDate = nil
			local line = file:read()
			while line do
				if string.find(line, "<when>") then
					local utcDateTime = line
					local gpsCoord = file:read()
					local utcDate, utcTime = GetDateTime(utcDateTime)
					if (indexFile == nil) or (indexDate ~= utcDate) then
						-- Close previous file
						if (indexFile ~= nil) then indexFile:close() end
						-- Open new file
						indexDate = utcDate
						indexFile = io.open(GPS_DATA_FOLDER .. indexDate .. ".dat", "a")
					end
					-- Add entry to file
					indexFile:write(utcDateTime .. "\n")
					indexFile:write(gpsCoord .. "\n")
				end
				line = file:read()
			end
			if (indexFile ~= nil) then indexFile:close() end
			file:close()
			AddProcessedFile(fileEntry)
		end
	end
end

-- Process Photos
function ProcessPhotos()
	local LrProgressScope = import 'LrProgressScope'
	local catalog = import "LrApplication".activeCatalog()
	local photos = catalog:findPhotos {
		searchDesc = {
			{
				criteria = "captureTime",
				operation = "in",
				value = "2011-02-12",
				value2 = "2012-02-12",
			},
			{
				criteria = "hasGPSData",
				operation = "==",
				value = false,
			},
			combine = "intersect",
		},
	}
	local progressScope = LrProgressScope {
			title = "Checking Photos",
	}

	for i, photo in ipairs( photos ) do
		if progressScope:isCanceled() then break end
		OutputToLog(photo:getFormattedMetadata('fileName'))
		progressScope:setPortionComplete( i, #photos )
	end
	progressScope:done()
end

-- PlugIn Task
function SagTask()
	for _, fileEntry in ipairs(ScanGPSFiles(KML_DATA_FOLDER)) do
		ProcessGPSFile(fileEntry)
	end
end

import "LrTasks".startAsyncTask(SagTask)
