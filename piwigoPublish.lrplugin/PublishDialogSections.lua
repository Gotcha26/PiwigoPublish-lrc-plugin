--[[

	PublishDialogSections.lua

	Publish Dialog Sections for Piwigo Publisher plugin

    Copyright (C) 2024 Fiona Boston <fiona@fbphotography.uk>.

    This file is part of PiwigoPublish

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

require "UIHelpers"

PublishDialogSections = {}

-- *************************************************
function PublishDialogSections.startDialog(propertyTable)
	log:info('PublishDialogSections.startDialog')
	if not propertyTable.LR_editingExistingPublishConnection then
		propertyTable.userName = nil
		propertyTable.userPW = nil
		propertyTable.host = nil
		propertyTable.Connected = false
		propertyTable.ConCheck = true
		propertyTable.ConStatus = "Not Connected"
	end
	-- Store the last saved connection details
	propertyTable.savedHost = propertyTable.host or ""
	propertyTable.savedUsername = propertyTable.userName or ""
	propertyTable.unsavedConnectionChanges = false
	propertyTable:addObserver('host', PiwigoAPI.ConnectionChange)
	propertyTable:addObserver('userName', PiwigoAPI.ConnectionChange)
	propertyTable:addObserver('userPW', PiwigoAPI.ConnectionChange)

	-- try to login
	LrTasks.startAsyncTask(function()
		local rv = PiwigoAPI.login(propertyTable)
	end)
end

-- *************************************************
function PublishDialogSections.endDialog(propertyTable, why)
	log:info('PublishDialogSections.endDialog')

	if why == 'ok' then
		-- User clicked Save - update our saved values
		propertyTable.savedHost = propertyTable.host
		propertyTable.savedUsername = propertyTable.userName
		propertyTable.unsavedConnectionChanges = false
	end
end

-- *************************************************
local function connectionDialog(f, propertyTable, pwInstance)
	local bind = LrView.bind
	local share = LrView.share

	return {
		title = "Piwigo Host Settings",
		bind_to_object = propertyTable,

		-- TOP: icon + version block
		UIHelpers.createPluginHeader(f, share, iconPath, pluginVersion),

		-- PW Host
		f:spacer { height = 1 },
		f:row {
			f:static_text {
				title = "",
				alignment = 'left',
				width_in_chars = 7,
			},

			f:static_text {
				title = "Piwigo Host:",
				font = "<system/bold>",
				alignment = 'left',
				width_in_chars = 8,
			},
			f:edit_field {
				value = bind 'host',
				alignment = 'left',
				width_in_chars = 30,
				validate = function(v, url)
					local sanitizedURL = PiwigoAPI.sanityCheckAndFixURL(url)
					if sanitizedURL == url then
						return true, url, ''
					elseif not (sanitizedURL == nil) then
						LrDialogs.message("Entered URL was autocorrected to " .. sanitizedURL)
						return true, sanitizedURL, ''
					end
					return false, url, 'Entered URL not valid.'
				end,
			},
			f:push_button {
				title = LrView.bind {
					key = 'Connected',
					transform = function(value)
						return value and "Disconnect" or "Check Connection"
					end
				},
				enabled = bind('ConCheck', propertyTable),
				font = "<system/bold>",
				action = function()
					LrTasks.startAsyncTask(function()
						if propertyTable.Connected then
							-- Déconnexion
							propertyTable.Connected = false
							propertyTable.ConCheck = true
							propertyTable.ConStatus = "Not Connected"
							propertyTable.SessionCookie = nil
							propertyTable.cookies = nil
							propertyTable.cookieHeader = nil
							propertyTable.userStatus = nil
							propertyTable.token = nil
							propertyTable.pwVersion = nil
						else
							-- Connexion
							if not PiwigoAPI.login(propertyTable) then
								LrDialogs.message("Connection NOT successful")
							end
						end
					end)
				end,
			},
		},

		-- Username
		f:spacer { height = 1 },
		f:row {
			f:static_text {
				title = "",
				alignment = 'left',
				width_in_chars = 7,
			},
			f:static_text {
				title = "User Name:",
				font = "<system/bold>",
				alignment = 'left',
				width_in_chars = 8,
				visible = bind 'hasNoError',
			},
			f:edit_field {
				value = bind 'userName',
				alignment = 'left',
				width_in_chars = 30,
			},
		},

		-- Password
		f:spacer { height = 1 },
		f:row {
			f:static_text {
				title = "",
				alignment = 'left',
				width_in_chars = 7,
			},
			f:static_text {
				title = "Password:",
				font = "<system/bold>",
				alignment = 'left',
				width_in_chars = 8,
				visible = bind 'hasNoError',
			},
			f:password_field {
				value = bind 'userPW',
				alignment = 'left',
				width_in_chars = 30,
			},
		},

		-- Status row
		f:spacer { height = 1 },
		f:row {
			f:static_text {
				title = bind 'ConStatus',
				font = "<system/bold>",
				alignment = 'center',
				fill_horizontal = 1,
			},
		},
	}
end

-- *************************************************
local function prefsDialog(f, propertyTable)
	local bind = LrView.bind
	local share = LrView.share

	return {
		title = "Piwigo Publish Service Configuration and Settings",
		bind_to_object = propertyTable,
		f:group_box {
			title = "Publish Service Set Up",
			font = "<system/bold>",
			fill_horizontal = 1,
			f:spacer { height = 2 },
			f:row {
				f:push_button {
					title = "Import Albums",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					tooltip = "Click to fetch the current album structure from the Piwigo Host above. Only albums the user has permission to see will be included",
					action = function(button)
						if propertyTable.unsavedConnectionChanges then
							LrDialogs.message("Unsaved Connection Changes",
								"You have changed the connection details. Please click 'Save' to save the publish service.",
								"info")
							return
						end
						local result = LrDialogs.confirm("Import Piwigo Albums",
							"Are you sure you want to import the album structure from Piwigo?\nExisting collections will be unaffected.",
							"Import", "Cancel")
						if result == "ok" then
							LrTasks.startAsyncTask(function()
								PiwigoAPI.importAlbums(propertyTable)
							end)
						end
					end,
				},
				f:static_text {
					title = "Import existing albums from Piwigo",
					font = "<system>",
					alignment = 'left',
					-- width = share 'labelWidth',
					width_in_chars = 50,
					tooltip = "Click to fetch the current album structure from the Piwigo Host above. Only albums the user has permission to see will be included",
				},
			},



			f:spacer { height = 1 },
			f:row {
				f:push_button {
					title = "Check and Link Piwigo Structure\n ",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					--enabled = false, -- temporary disabled
					tooltip = "Check Piwigo album structure against local collection / set structure",
					action = function(button)
						if propertyTable.unsavedConnectionChanges then
							LrDialogs.message("Unsaved Connection Changes",
								"You have changed the connection details. Please click 'Save' to save the publish service.",
								"info")
							return
						end
						local result = LrDialogs.confirm("Check / link Piwigo Structure",
							"Are you sure you want to check / link Piwigo Structure?\nExisting collections will be unaffected.",
							"Check", "Cancel")
						if result == "ok" then
							LrTasks.startAsyncTask(function()
								PiwigoAPI.validatePiwigoStructure(propertyTable)
							end)
						end
					end,
				},
				f:static_text {
					title = "Piwigo structure will be checked against local collection / set structure.\nMissing Piwigo albums will be created and links checked / updated",
					font = "<system>",
					alignment = 'left',
					-- width = share 'labelWidth',
					-- width_in_chars = 50,
					tooltip = "Piwigo structure will be checked against local collection / set structure.\nMissing Piwigo albums will be created and links checked / updated"
				},
			},

			f:spacer { height = 1 },
			f:row {
				f:push_button {
					title = "Clone Existing Publish Service\n ",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					--enabled = false, -- temporary disabled
					tooltip = "Clone existing publish service (collections/sets and links to Piwigo)",
					action = function(button)
						if propertyTable.unsavedConnectionChanges then
							LrDialogs.message("Unsaved Connection Changes",
								"You have changed the connection details. Please click 'Save' to save the publish service.",
								"info")
							return
						end
						LrTasks.startAsyncTask(function()
							PWImportService.selectService(propertyTable)
						end)
					end,
				},
				f:static_text {
					title = "Collection/Set structure and images of selected Publish Service\nwill be cloned to this one.",
					font = "<system>",
					alignment = 'left',
					-- width = share 'labelWidth',
					-- width_in_chars = 50,
					tooltip = "Selected Collection/Set structure and images of selected Publish Service\nwill be cloned to this one."
				},
			},

			f:spacer { height = 1 },

			f:row {
				f:push_button {
					title = "Create Special Collections\n ",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					--enabled = false, -- temporary disabled
					tooltip = "Create special publish collections for publish collection sets, allowing images to be published to Piwigo albums with sub-albums",
					action = function(button)
						if propertyTable.unsavedConnectionChanges then
							LrDialogs.message("Unsaved Connection Changes",
								"You have changed the connection details. Please click 'Save' to save the publish service.",
								"info")
							return
						end
						local result = LrDialogs.confirm("Create Special Collections",
							"Are you sure you want to create Special Collections?\nExisting collections may be updated and missing Piwigo albums will be created.",
							"Create", "Cancel")
						if result == "ok" then
							LrTasks.startAsyncTask(function()
								PiwigoAPI.specialCollections(propertyTable)
							end)
						end
					end,
				},
				f:static_text {
					title = "Create special publish collections to allow images to be published\nto albums with sub-albums on Piwigo",
					alignment = 'left',
					font = "<system>",
					-- width = share 'labelWidth',
					-- width_in_chars = 50,
					tooltip = "Create special collections to allow images to be published to Piwigo\nalbums with sub-albums - which is not natively supported on LrC"
				},
			},
			f:spacer { height = 1 },

			f:row {
				f:push_button {
					title = "Album Summary\n ",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					tooltip = "Show a summary of all albums with photo counts (published, modified, new to publish)",
					action = function(button)
						LrTasks.startAsyncTask(function()
								local found, service = PiwigoAPI.getPublishService(propertyTable)
								if not found or not service then
									LrDialogs.message("Album Summary", "Could not find the publish service. Please save the connection first.")
									return
								end

								local summary = utils.buildAlbumSummary(service)
								local allNodes = summary.nodes
								local totals = summary.totals

								if #allNodes == 0 then
									LrDialogs.message("Album Summary", "No albums with photos found.")
									return
								end

								-- Build LrView dialog
								local dlgF = LrView.osFactory()

								-- Column widths (pixels)
								local colName = 370
								local colNum = 45
								local indentPx = 20

								-- Count leaf albums
								local albumCount = 0
								for _, node in ipairs(allNodes) do
									if node.type == "collection" then albumCount = albumCount + 1 end
								end

								local function mkRow(indent, nameStr, nameFont, pub, pubFont, mod, modFont, new, newFont)
									return dlgF:row {
										dlgF:static_text { title = "", width = indent },
										dlgF:static_text {
											title = nameStr, font = nameFont,
											width = colName - indent, truncation = 'middle',
										},
										dlgF:static_text {
											title = pub, font = pubFont or "<system>",
											width = colNum, alignment = 'right',
										},
										dlgF:static_text {
											title = mod, font = modFont or "<system>",
											width = colNum, alignment = 'right',
										},
										dlgF:static_text {
											title = new, font = newFont or "<system>",
											width = colNum, alignment = 'right',
										},
									}
								end

								-- Header
								local headerRow = mkRow(0, "Album", "<system/bold>",
									"Pub.", "<system/bold>", "Mod.", "<system/bold>", "New", "<system/bold>")

								-- Build data rows
								local dataRows = {}
								for _, node in ipairs(allNodes) do
									local indent = node.depth * indentPx
									local modStr = node.modified > 0 and tostring(node.modified) or "-"
									local newStr = node.new > 0 and tostring(node.new) or "-"
									local modFont = node.modified > 0 and "<system/bold>" or "<system>"
									local newFont = node.new > 0 and "<system/bold>" or "<system>"

									if node.type == "set" then
										-- Parent set: separator + bold name + sub-totals in italic
										if #dataRows > 0 then
											table.insert(dataRows, dlgF:spacer { height = 6 })
										end
										table.insert(dataRows, mkRow(indent,
											node.name, "<system/bold>",
											tostring(node.published), "<system>",
											modStr, modFont,
											newStr, newFont
										))
									else
										-- Leaf album
										local hasPending = node.modified > 0 or node.new > 0
										local nameFont = hasPending and "<system/bold>" or "<system>"
										table.insert(dataRows, mkRow(indent,
											node.name, nameFont,
											tostring(node.published), "<system>",
											modStr, modFont,
											newStr, newFont
										))
									end
								end

								-- Totals row
								local totalRow = mkRow(0,
									"TOTAL (" .. albumCount .. " albums)", "<system/bold>",
									tostring(totals.published), "<system/bold>",
									tostring(totals.modified), "<system/bold>",
									tostring(totals.new), "<system/bold>"
								)

								-- Assemble
								local contentItems = {
									headerRow,
									dlgF:separator { fill_horizontal = 1 },
								}
								for _, dr in ipairs(dataRows) do
									table.insert(contentItems, dr)
								end
								table.insert(contentItems, dlgF:separator { fill_horizontal = 1 })
								table.insert(contentItems, totalRow)
								contentItems.spacing = dlgF:control_spacing()

								local contents = dlgF:column(contentItems)

								local scrolled = dlgF:scrolled_view {
									width = colName + colNum * 3 + 40,
									height = math.min(500, 80 + #allNodes * 20),
									contents,
								}

								LrDialogs.presentModalDialog({
									title = "Album Summary — " .. (propertyTable.LR_publish_connectionName or ""),
									contents = scrolled,
									actionVerb = "OK",
									cancelVerb = "< exclude >",
								})
						end)
					end,
				},
				f:static_text {
					title = "Show a summary of all albums with photo counts\n(published, modified, new to publish)",
					font = "<system>",
					alignment = 'left',
					tooltip = "Display a summary dialog listing all albums and their photo status counts"
				},
			},
			f:spacer { height = 1 },

			f:row {
				f:push_button {
					title = "Server Info\n ",
					font = "<system>",
					width = share 'buttonwidth',
					enabled = bind('Connected', propertyTable),
					tooltip = "Show server capabilities and video support status",
					action = function(button)
						LrTasks.startAsyncTask(function()
								local videoSupport = PiwigoAPI.getServerVideoSupport(propertyTable)
								if not videoSupport.status then
									LrDialogs.message("Server Info", "Could not retrieve server information. Check your connection.")
									return
								end

								local dlgF = LrView.osFactory()
								local colLabel = 220
								local colValue = 350

								local function mkInfoRow(label, value, valueFont)
									return dlgF:row {
										dlgF:static_text {
											title = label,
											font = "<system/bold>",
											width = colLabel,
											alignment = 'right',
										},
										dlgF:static_text {
											title = tostring(value),
											font = valueFont or "<system>",
											width = colValue,
											alignment = 'left',
										},
									}
								end

								-- Helper: font for status display
								local function statusFont(ok)
									return ok and "<system>" or "<system/bold>"
								end

								-- Video support status
								local videoStatus
								local videoFont = "<system>"
								if videoSupport.videoJsActive then
									local name = videoSupport.videoJsName or "VideoJS"
									videoStatus = name .. " — Active"
								elseif videoSupport.videoJsInstalled then
									local name = videoSupport.videoJsName or "VideoJS"
									videoStatus = name .. " — INACTIVE"
									videoFont = "<system/bold>"
								else
									videoStatus = "Not installed"
									videoFont = "<system/bold>"
								end

								local infos = videoSupport.serverInfos
								local cfg = videoSupport.serverConfig  -- may be nil if plugin not installed

								-- Section header helper
								local function mkSectionHeader(title)
									return dlgF:row {
										dlgF:static_text {
											title = title,
											font = "<system/bold>",
											width = colLabel + colValue,
										},
									}
								end

								local rows = {}

								-- ===== Piwigo Gallery =====
								table.insert(rows, mkSectionHeader("Piwigo Gallery"))
								table.insert(rows, dlgF:separator { fill_horizontal = 1 })
								table.insert(rows, mkInfoRow("Version:", videoSupport.piwigoVersion))
								table.insert(rows, mkInfoRow("Photos:", infos.nb_elements or "N/A"))
								table.insert(rows, mkInfoRow("Albums:", infos.nb_categories or "N/A"))
								table.insert(rows, mkInfoRow("Tags:", infos.nb_tags or "N/A"))
								table.insert(rows, mkInfoRow("Users:", infos.nb_users or "N/A"))
								table.insert(rows, mkInfoRow("Comments:", infos.nb_comments or "N/A"))

								if cfg and cfg.piwigo then
									local allTypes = cfg.piwigo.upload_form_all_types
									table.insert(rows, mkInfoRow("All file types upload:",
										allTypes and "Enabled" or "Disabled",
										statusFont(allTypes)))
									if cfg.piwigo.file_ext then
										local exts = table.concat(cfg.piwigo.file_ext, ", ")
										table.insert(rows, mkInfoRow("Allowed extensions:", exts))
									end
								end

								table.insert(rows, dlgF:spacer { height = 6 })

								-- ===== Server & PHP =====
								if cfg then
									table.insert(rows, mkSectionHeader("Server && PHP"))
									table.insert(rows, dlgF:separator { fill_horizontal = 1 })

									if cfg.server then
										table.insert(rows, mkInfoRow("OS:", cfg.server.os or "N/A"))
										table.insert(rows, mkInfoRow("Web Server:", cfg.server.software or "N/A"))
									end

									if cfg.php then
										table.insert(rows, mkInfoRow("PHP Version:", cfg.php.version or "N/A"))
										table.insert(rows, mkInfoRow("upload_max_filesize:", cfg.php.upload_max_filesize or "N/A"))
										table.insert(rows, mkInfoRow("post_max_size:", cfg.php.post_max_size or "N/A"))
										table.insert(rows, mkInfoRow("memory_limit:", cfg.php.memory_limit or "N/A"))
										table.insert(rows, mkInfoRow("max_execution_time:", (cfg.php.max_execution_time or "N/A") .. "s"))
									end

									table.insert(rows, dlgF:spacer { height = 6 })

									-- ===== Graphics =====
									table.insert(rows, mkSectionHeader("Graphics Libraries"))
									table.insert(rows, dlgF:separator { fill_horizontal = 1 })

									if cfg.graphics then
										if cfg.graphics.gd and type(cfg.graphics.gd) == "table" then
											table.insert(rows, mkInfoRow("GD:", cfg.graphics.gd.version or "Installed"))
										else
											table.insert(rows, mkInfoRow("GD:", "Not available", "<system/bold>"))
										end
										if cfg.graphics.imagick and type(cfg.graphics.imagick) == "table" then
											table.insert(rows, mkInfoRow("ImageMagick:", cfg.graphics.imagick.version or "Installed"))
										else
											table.insert(rows, mkInfoRow("ImageMagick:", "Not available"))
										end
									end

									table.insert(rows, dlgF:spacer { height = 6 })

									-- ===== Video Tools =====
									table.insert(rows, mkSectionHeader("Video && Media Tools"))
									table.insert(rows, dlgF:separator { fill_horizontal = 1 })
								end

								table.insert(rows, mkInfoRow("VideoJS plugin:", videoStatus, videoFont))

								if cfg then
									-- exec() status
									if cfg.php and cfg.php.exec_available ~= nil then
										if not cfg.php.exec_available then
											table.insert(rows, mkInfoRow("exec():", "DISABLED", "<system/bold>"))
											table.insert(rows, dlgF:row {
												dlgF:static_text { title = "", width = colLabel },
												dlgF:static_text {
													title = "CLI tools (FFmpeg, ExifTool) cannot be detected.\nContact your hosting provider.",
													font = "<system>", width = colValue, height_in_lines = 2,
												},
											})
										end
									end

									if cfg.ffmpeg then
										local ffNotice = cfg.ffmpeg.notice
										local ffVer = cfg.ffmpeg.installed and (cfg.ffmpeg.version or "Installed")
											or (ffNotice or "Not found")
										table.insert(rows, mkInfoRow("FFmpeg:",
											ffVer, statusFont(cfg.ffmpeg.installed)))
										if not cfg.ffmpeg.installed and not cfg.ffmpeg.notice then
											table.insert(rows, dlgF:row {
												dlgF:static_text { title = "", width = colLabel },
												dlgF:static_text {
													title = "Without FFmpeg, videos will upload but Piwigo\nwill not generate a custom thumbnail for them.",
													font = "<system>", width = colValue, height_in_lines = 2,
												},
											})
										end
									end
									if cfg.ffprobe then
										local fpVer = cfg.ffprobe.installed and (cfg.ffprobe.version or "Available")
											or "Not found"
										table.insert(rows, mkInfoRow("FFprobe:",
											fpVer, statusFont(cfg.ffprobe.installed)))
									end

									if cfg.exiftool then
										local etVer = cfg.exiftool.installed and ("v" .. (cfg.exiftool.version or "?"))
											or (cfg.exiftool.notice or "Not found")
										table.insert(rows, mkInfoRow("ExifTool:",
											etVer, statusFont(cfg.exiftool.installed)))
									end

									if cfg.mediainfo then
										local miVer = cfg.mediainfo.installed and (cfg.mediainfo.version or "Installed")
											or (cfg.mediainfo.notice or "Not found")
										table.insert(rows, mkInfoRow("MediaInfo:",
											miVer, statusFont(cfg.mediainfo.installed)))
									end

									table.insert(rows, dlgF:spacer { height = 6 })

									-- ===== Video Readiness =====
									table.insert(rows, mkSectionHeader("Video Upload Readiness"))
									table.insert(rows, dlgF:separator { fill_horizontal = 1 })

									if cfg.piwigo then
										local videoReady = cfg.piwigo.video_ready
										table.insert(rows, mkInfoRow("Video upload:",
											videoReady and "Ready" or "NOT CONFIGURED",
											statusFont(videoReady)))

										local allTypes = cfg.piwigo.upload_form_all_types
										table.insert(rows, mkInfoRow("All file types:",
											allTypes and "Enabled" or "Disabled",
											statusFont(allTypes)))

										if cfg.piwigo.video_ext_configured then
											local vExts = cfg.piwigo.video_ext_configured
											if type(vExts) == "table" and #vExts > 0 then
												table.insert(rows, mkInfoRow("Video extensions:",
													table.concat(vExts, ", ")))
											else
												table.insert(rows, mkInfoRow("Video extensions:",
													"None configured", "<system/bold>"))
											end
										end

										local writable = cfg.piwigo.local_config_writable
										table.insert(rows, mkInfoRow("Config writable:",
											writable and "Yes" or "No (read-only)",
											statusFont(writable)))

										-- Enable Video button if not ready and companion is available
										if not videoReady and videoSupport.companionAvailable then
											table.insert(rows, dlgF:spacer { height = 6 })
											table.insert(rows, dlgF:row {
												dlgF:static_text { title = "", width = colLabel },
												dlgF:push_button {
													title = "Enable Video Support",
													width = 200,
													action = function()
														LrTasks.startAsyncTask(function()
															local result = PiwigoAPI.enableVideoSupport(propertyTable)
															if result.status == "ok" then
																LrDialogs.message("Video Support Enabled",
																	result.message or "Video support has been configured.",
																	"info")
															elseif result.status == "already_configured" then
																LrDialogs.message("Video Support",
																	result.message or "Already configured.",
																	"info")
															else
																LrDialogs.message("Video Support Error",
																	result.message or "Failed to enable video support.",
																	"critical")
															end
														end)
													end,
												},
											})
										end
									end
								else
									-- Companion plugin not installed
									table.insert(rows, dlgF:spacer { height = 6 })
									table.insert(rows, dlgF:row {
										dlgF:static_text { title = "", width = colLabel },
										dlgF:static_text {
											title = "Install the 'PiwigoPublish Companion' plugin\non your Piwigo server for detailed diagnostics\nand automatic video configuration.",
											font = "<system>", width = colValue, height_in_lines = 3,
										},
									})
								end

								if not videoSupport.videoJsActive then
									table.insert(rows, dlgF:spacer { height = 4 })
									table.insert(rows, dlgF:row {
										dlgF:static_text { title = "", width = colLabel },
										dlgF:static_text {
											title = "Install and activate the VideoJS plugin\nfrom Piwigo administration for video playback.",
											font = "<system>", width = colValue, height_in_lines = 2,
										},
									})
								end

								rows.spacing = dlgF:control_spacing()
								local contents = dlgF:column(rows)

								local scrolled = dlgF:scrolled_view {
									width = colLabel + colValue + 50,
									height = 500,
									contents,
								}

								LrDialogs.presentModalDialog({
									title = "Server Info — " .. (propertyTable.host or ""),
									contents = scrolled,
									actionVerb = "OK",
									cancelVerb = "< exclude >",
								})
						end)
					end,
				},
				f:static_text {
					title = "Show server capabilities and video support status",
					font = "<system>",
					alignment = 'left',
					tooltip = "Display server information including Piwigo version, statistics, and video plugin status"
				},
			},
			f:spacer { height = 1 },

		},

		f:group_box {
			title = "Metadata Settings",
			font = "<system/bold>",
			fill_horizontal = 1,

			f:spacer { height = 2 },

			f:row {
				f:static_text {
					title = "Title: ",
					font = "<system>",
					alignment = 'right',
					width_in_chars = 8,
				},
				f:edit_field {
					value = bind 'mdTitle',
					font = "<system>",
					alignment = 'left',
					width_in_chars = 60,
					height_in_lines = 3,
				},
			},

			f:row {
				f:static_text {
					title = "Description: ",
					font = "<system>",
					alignment = 'right',
					width_in_chars = 8,
				},
				f:edit_field {
					value = bind 'mdDescription',
					font = "<system>",
					alignment = 'left',
					width_in_chars = 60,
					height_in_lines = 3,
				},
			},
		},

		f:spacer { height = 2 },

		UIHelpers.createKeywordSettingsGroupBox(f, bind),
		f:spacer { height = 2 },
		f:group_box {
			title = "Other Settings",
			font = "<system/bold>",
			fill_horizontal = 1,
			f:spacer { height = 1 },




			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "Album description :",
					font = "<system>",
					alignment = 'right',
					width_in_chars = 18,
				},
				f:popup_menu {
					tooltip = "How to resolve conflicts between Lightroom and Piwigo album descriptions",
					value = bind 'albumDescSyncMode',
					items = {
						{ title = "Ask on conflict",       value = "ask" },
						{ title = "Always use Lightroom",  value = "lightroom" },
						{ title = "Always use Piwigo",     value = "piwigo" },
					},
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "Album privacy :",
					font = "<system>",
					alignment = 'right',
					width_in_chars = 18,
				},
				f:popup_menu {
					tooltip = "How to resolve conflicts between Lightroom and Piwigo album privacy status",
					value = bind 'albumStatusSyncMode',
					items = {
						{ title = "Ask on conflict",       value = "ask" },
						{ title = "Always use Lightroom",  value = "lightroom" },
						{ title = "Always use Piwigo",     value = "piwigo" },
					},
				},
			},
			f:spacer { height = 1 },

			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "",
					alignment = 'right',
					width_in_chars = 7,
				},
				f:checkbox {
					title = "Synchronise Photo Sort Order",
					font = "<system>",
					tooltip = "If checked, the photo display order in Lightroom will be sent to Piwigo after each publish",
					value = bind 'syncPhotoSortOrder',
				},
			},
			f:spacer { height = 1 },

			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "",
					alignment = 'right',
					width_in_chars = 7,
				},
				f:checkbox {
					title = "Synchronise comments as part of a Publish Process",
					font = "<system>",
					tooltip = "When checked, comments will be synchronised for all photos in a collection during a publish operation",
					value = bind 'syncCommentsPublish',
				},
			},
			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "",
					alignment = 'right',
					width_in_chars = 7,
				},
				f:checkbox {
					title = "Only include Published Photos",
					enabled = bind('syncCommentsPublish', propertyTable),
					font = "<system>",
					tooltip = "When checked, only photos being published will have comments synchronised",
					value = bind 'syncCommentsPubOnly',
				},
			},


		},
	}
end
--
-- *************************************************
-- Video Toolkit dialog section (Phase 2A)
-- *************************************************
local VTK_PRESETS = { "small", "medium", "large", "xlarge", "xxl", "origin" }
local VTK_PRESET_LABELS = { "Small (480p)", "Medium (720p)", "Large (1080p)", "XLarge (1440p)", "XXL (2160p)", "Origin (no transcode)" }

local function videoDialog(f, propertyTable)
	local bind = LrView.bind
	local share = LrView.share

	-- Build preset items list for popup_menu
	local presetItems = {}
	for i, key in ipairs(VTK_PRESETS) do
		presetItems[#presetItems + 1] = { title = VTK_PRESET_LABELS[i], value = key }
	end

	return {
		title = "Video Settings",
		bind_to_object = propertyTable,

		f:group_box {
			title = "Video Toolkit",
			font = "<system>",
			fill_horizontal = 1,

			f:spacer { height = 2 },

			-- Enable/disable toggle
			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = "Enable Video Toolkit (local transcoding)",
					fill_horizontal = 1,
					value = bind "vtkEnabled",
					tooltip = "When enabled, videos are transcoded locally by the Video Toolkit before upload.",
				},
			},

			f:row {
				fill_horizontal = 1,
				f:checkbox {
					title = "Include video files",
					fill_horizontal = 1,
					value = bind "vtkIncludeVideo",
					tooltip = "Include video files in publications. Requires Video Toolkit to be enabled.",
					enabled = bind "vtkEnabled",
				},
			},

			f:spacer { height = 4 },

			-- Preset + poster settings (enabled only when vtkEnabled = true)
			f:separator { fill_horizontal = 1 },
			f:row { f:static_text { title = "Encoding Settings", fill_horizontal = 1 } },
			f:column {
				fill_horizontal = 1,
				enabled = bind "vtkEnabled",

				f:spacer { height = 2 },

				f:row {
					f:static_text {
						title = "Default preset:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:popup_menu {
						value = bind "vtkDefaultPreset",
						items = presetItems,
						tooltip = "Preset applied to all videos unless overridden per collection.",
					},
				},

				f:spacer { height = 2 },

				f:row {
					f:static_text {
						title = "Poster thumbnail:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:checkbox {
						title = "Generate poster (JPG)",
						fill_horizontal = 1,
						value = bind "vtkGeneratePoster",
						tooltip = "Extract a JPG thumbnail from the video and upload as representative image.",
					},
				},

				f:row {
					f:static_text {
						title = "Poster at:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkPosterTimestamp",
						width_in_chars = 4,
						tooltip = "Percentage of video duration for the thumbnail frame (0–95).",
						enabled = bind "vtkGeneratePoster",
					},
					f:static_text {
						title = "% of duration",
						alignment = 'left',
					},
				},
			},

			f:spacer { height = 4 },

			-- Advanced paths (collapsible group_box)
			f:separator { fill_horizontal = 1 },
			f:row { f:static_text { title = "Advanced — Tool Paths", fill_horizontal = 1 } },
			f:column {
				fill_horizontal = 1,
				enabled = bind "vtkEnabled",

				f:spacer { height = 2 },

				f:row {
					f:static_text {
						title = "Toolkit:",
						alignment = 'right',
						width = share 'vtk_label_w',
				},
					f:edit_field {
						value = bind "vtkToolkitPath",
						placeholder_string = "(auto: <plugin>/video-toolkit/video_toolkit.py)",
						fill_horizontal = 1,
						tooltip = "Path to video_toolkit.py. Leave empty to use the bundled toolkit next to the plugin.",
				},
				},

				f:row {
					f:static_text {
						title = "Python:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkPythonPath",
						fill_horizontal = 1,
						tooltip = "Full path to python.exe (leave blank for auto-detect).",
						placeholder_string = "(auto-detect)",
					},
				},

				f:row {
					f:static_text {
						title = "FFmpeg:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkFFmpegPath",
						fill_horizontal = 1,
						tooltip = "Full path to ffmpeg.exe (leave blank for auto-detect).",
						placeholder_string = "(auto-detect)",
					},
				},

				f:row {
					f:static_text {
						title = "FFprobe:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkFFprobePath",
						fill_horizontal = 1,
						tooltip = "Full path to ffprobe.exe (leave blank for auto-detect).",
						placeholder_string = "(auto-detect)",
					},
				},

				f:row {
					f:static_text {
						title = "ExifTool:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkExifToolPath",
						fill_horizontal = 1,
						tooltip = "Full path to exiftool.exe (leave blank for auto-detect, optional).",
						placeholder_string = "(auto-detect, optional)",
					},
				},

				f:row {
					f:static_text {
						title = "Presets file:",
						alignment = 'right',
						width = share 'vtk_label_w',
					},
					f:edit_field {
						value = bind "vtkPresetsFile",
						fill_horizontal = 1,
						tooltip = "Path to a custom presets.json file (leave blank for built-in presets).",
						placeholder_string = "(built-in presets)",
					},
				},

				f:spacer { height = 2 },
			},

			f:spacer { height = 4 },

			-- Status + action buttons
			f:separator { fill_horizontal = 1 },
			f:row { f:static_text { title = "Status", fill_horizontal = 1 } },
			f:column {
				fill_horizontal = 1,
				enabled = bind "vtkEnabled",

				f:spacer { height = 2 },

				f:row {
					f:static_text {
						title = LrView.bind {
							keys = { "vtkEnabled", "vtkPythonPath", "vtkFFmpegPath" },
							operation = function(_, values, _)
								if not values.vtkEnabled then
									return "Video Toolkit disabled."
								end
								return "Use 'Check Tools' to verify installation."
							end,
						},
						fill_horizontal = 1,
						alignment = 'left',
						font = "<system>",
					},
				},

				f:spacer { height = 2 },

				f:row {
					f:push_button {
						title = "Check Tools...",
						font = "<system>",
						width = share 'buttonwidth',
						enabled = bind "vtkEnabled",
						tooltip = "Run Video Toolkit to verify Python, FFmpeg and ExifTool installations.",
						action = function(_)
							LrTasks.startAsyncTask(function()
								local python     = utils.resolveTool(propertyTable.vtkPythonPath, "python")
								local plugin     = rawget(_G, "_PLUGIN")
								local toolkitPath = utils.resolveToolkitPath(propertyTable.vtkToolkitPath, plugin.path)
								local isWindows  = (LrSystemInfo.osVersion():lower():find("win") ~= nil)
								local installCmd = isWindows and "winget install --id Gyan.FFmpeg" or "brew install ffmpeg"

								local tools = {
									{ key = "vtkFFmpegPath",   name = "FFmpeg",   val = propertyTable.vtkFFmpegPath },
									{ key = "vtkFFprobePath",  name = "FFprobe",  val = propertyTable.vtkFFprobePath },
									{ key = "vtkExifToolPath", name = "ExifTool", val = propertyTable.vtkExifToolPath },
								}
								for _, t in ipairs(tools) do
									if t.val and t.val ~= "" and not utils.fileExists(t.val) then
										LrDialogs.message("Video Toolkit — Invalid Path",
											"The configured path for " .. t.name .. " is invalid:\n" .. t.val .. "\n\nFix the path in Advanced settings, or clear the field to let the toolkit detect it automatically.", "critical")
										return
									end
								end

								if not utils.fileExists(python) then
									LrDialogs.message("Video Toolkit — Python Not Found",
										"Python was not found at:\n" .. python .. "\n\nFix the path in Advanced settings, or clear the field for auto-detect.", "critical")
									return
								end
								if not utils.fileExists(toolkitPath) then
									LrDialogs.message("Video Toolkit — Script Not Found",
										"video_toolkit.py not found at:\n" .. toolkitPath .. "\n\nFix the path in Advanced settings, or clear the field for auto-detect.", "critical")
									return
								end

								local outFile = LrPathUtils.child(LrPathUtils.getStandardFilePath("temp"), "vtk_check.json")
								local innerCmd = '"' .. python .. '" "' .. toolkitPath .. '" --mode check > "' .. outFile .. '" 2>&1'
								local cmd = isWindows and ('cmd /c "' .. innerCmd .. '"') or innerCmd
								local result = LrTasks.execute(cmd)
								local checkOutput = ""
								local fh = io.open(outFile, "r")
								if fh then checkOutput = fh:read("*a"); fh:close() end

								if result == 0 then
									local ok, parsed = pcall(JSON.decode, JSON, checkOutput)
									if ok and parsed then
										local function fillIfEmpty(key, val)
											if val and val ~= "not found" and (not propertyTable[key] or propertyTable[key] == "") then
												propertyTable[key] = val
											end
										end
										fillIfEmpty("vtkFFmpegPath",  parsed.ffmpeg)
										fillIfEmpty("vtkFFprobePath", parsed.ffprobe)
										fillIfEmpty("vtkExifToolPath", parsed.exiftool)
									end
									if not (propertyTable.vtkPythonPath and propertyTable.vtkPythonPath ~= "") then
										propertyTable.vtkPythonPath = python
									end
									if not (propertyTable.vtkToolkitPath and propertyTable.vtkToolkitPath ~= "") then
										propertyTable.vtkToolkitPath = toolkitPath
									end
									LrDialogs.message("Video Toolkit — OK",
										"All tools verified and working.\n\nDetected paths have been filled in Advanced settings.", "info")
								else
									LrDialogs.message("Video Toolkit — FFprobe Not Found",
										"Python and the toolkit are working, but ffprobe was not found.\n\n"
										.. "Install FFmpeg (includes ffprobe):\n  " .. installCmd .. "\n\n"
										.. "Or set the FFprobe path in Advanced settings.", "critical")
								end
						end)
						end,
					},
					f:push_button {
						title = "Pre-render Now...",
						font = "<system>",
						width = share 'buttonwidth',
						enabled = bind "vtkEnabled",
						tooltip = "Pre-process all videos in the current publish service without publishing them.",
						action = function(_)
							LrDialogs.message("Pre-render",
								"Pre-render will be available in a future update.\n\nFor now, videos are processed automatically during publish.",
								"info")
						end,
					},
				},

				f:spacer { height = 2 },
			},
		},
	}
end

-- *************************************************
function PublishDialogSections.sectionsForTopOfDialog(f, propertyTable)
	local conDlg = connectionDialog(f, propertyTable)
	local prefDlg = prefsDialog(f, propertyTable)
	local videoDlg = videoDialog(f, propertyTable)
	if utils.nilOrEmpty(propertyTable.host) or utils.nilOrEmpty(propertyTable.userName) or utils.nilOrEmpty(propertyTable.userPW) then
		propertyTable.Connected = false
		propertyTable.ConCheck = true
		propertyTable.ConStatus = "Not Connected"
	else

	end

	return { conDlg, prefDlg, videoDlg }
end

-- *************************************************
function PublishDialogSections.viewForCollectionSettings(f, propertyTable, info)
	return {

		title = "Piwigo Service View for Collection Settings",
		bind_to_object = propertyTable,
		f:row {
			f:static_text {
				title = "For entire Piwigo Publish Service",
				alignment = 'left',
				fill_horizontal = 1,
			},
		},
	}
end

-- *************************************************
function PublishDialogSections.sectionsForBottomOfDialog(f, propertyTable)
	return {}
end
