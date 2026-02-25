--[[

	UIHelpers.lua

	UI Helper Functions for Piwigo Publisher plugin

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

UIHelpers = {}

-- Functions for UI Management
-- *************************************************
local function valueEqual(a, b)
	-- Define a value_equal function for the popup_menu
	return a == b
end

-- *************************************************
-- Create plugin header with icon and version information
-- Returns a row containing icon + plugin name + version
-- *************************************************
function UIHelpers.createPluginHeader(f, share, iconPath, pluginVersion)
	local INDENT_PIXELS = 14

	return f:row {
		f:picture {
			alignment = 'left',
			value = iconPath,
		},
		f:column {
			spacing = f:control_spacing(),
			f:spacer { height = 1 },
			f:row {
				f:spacer { width = INDENT_PIXELS },
				f:static_text {
					title = "Piwigo Publisher Plugin",
					font = "<system/bold>",
					alignment = 'left',
					width = share 'labelWidth',
				},
			},
			f:row {
				f:spacer { width = INDENT_PIXELS },
				f:static_text {
					title = "Plugin Version",
					alignment = 'left',
				},
				f:static_text {
					title = pluginVersion,
					alignment = 'left',
					width = share 'labelWidth',
				},
			},
		},
	}
end

-- *************************************************
-- Create Piwigo Album Settings UI section
-- Returns a group_box with album description and private checkbox
-- *************************************************
function UIHelpers.createPiwigoAlbumSettingsUI(f, share, bind, collectionSettings, publishSettings)
	return f:group_box {
		title = "Piwigo Album Settings",
		font = "<system/bold>",
		size = 'regular',
		fill_horizontal = 1,
		bind_to_object = assert(collectionSettings),
		f:column {
			spacing = f:control_spacing(),

			f:separator { fill_horizontal = 1 },

			f:row {
				fill_horizontal = 1,
				f:static_text { title = "Album Description:", font = "<system>", alignment = 'right', width = share 'label_width', },
				f:edit_field {
					enabled = true,
					value = bind 'albumDescription',
					fill_horizontal = 1,
					width_in_chars = 70,
					font = "<system>",
					alignment = 'left',
					height_in_lines = 4,
				},
			},

			f:row {
				fill_horizontal = 1,
				f:static_text {
					title = "",
					alignment = 'right',
					width = share 'label_width',
				},
				f:checkbox {
					title = "",
					tooltip = "If checked, this album will be private on Piwigo",
					value = bind 'albumPrivate',
				},
				f:static_text {
					title = "Album is Private",
					font = "<system>",
				}
			}
		}
	}
end

-- *************************************************
-- Create Keyword Filtering inner elements (help texts + exclusion/inclusion fields)
-- Returns a flat list of UI elements to be inserted into a parent container
-- Options:
--   showOverrideHint (bool) : show "Leave empty to use global settings" text
--   widthInChars (number)   : width of edit fields (default 30)
--   heightInLines (number)  : height of edit fields (default 8)
--   fillColumns (bool)      : apply fill_horizontal on columns
-- *************************************************
function UIHelpers.createKeywordFilteringFields(f, bind, options)
	options               = options or {}
	local widthInChars    = options.widthInChars or 30
	local heightInLines   = options.heightInLines or 8
	local fillColumns     = options.fillColumns or false

	local exclusionColDef = {
		f:static_text {
			title = "Exclusion Rules\n(keywords matching these rules will not be sent to Piwigo)",
			font = "<system/bold>",
		},
		f:edit_field {
			value = bind 'KwFilterExclude',
			font = "<system>",
			alignment = 'left',
			width_in_chars = widthInChars,
			height_in_lines = heightInLines,
			fill_horizontal = fillColumns and 1 or nil,
			--tooltip = "Photos with any keyword matching these rules will not be published. One rule per line.",
			tooltip = "Keywords matching these rules will not sent to Piwigo. One rule per line. Overrides inclusion rules - if a keyword matches both exclusion and inclusion rules, it will be excluded.",
		},
	}
	if fillColumns then exclusionColDef.fill_horizontal = 1 end

	local inclusionColDef = {
		f:static_text {
			title = "Inclusion Rules\n(only keywords matching these rules will be sent to Piwigo)",
			font = "<system/bold>",
		},
		f:edit_field {
			value = bind 'KwFilterInclude',
			font = "<system>",
			alignment = 'left',
			width_in_chars = widthInChars,
			height_in_lines = heightInLines,
			fill_horizontal = fillColumns and 1 or nil,
			--tooltip = "Photos must have at least one keyword matching these rules to be published. Leave empty to allow all. One rule per line.",
			tooltip = "Only keywords matching these rules will be sent to Piwigo. One rule per line. Exclusion rules take precedence over inclusion rules - if a keyword matches both exclusion and inclusion rules, it will be excluded.",
		},
	}
	if fillColumns then inclusionColDef.fill_horizontal = 1 end

	local elements = {}
	if not options.showOverrideHint then
		-- options.showOverrideHint is set to false for the PublishDialogSections
		elements[#elements + 1] = f:static_text {
			title = "Keyword Filtering Settings",
			font = "<system/bold>",
		}
	end
	elements[#elements + 1] = f:static_text {
		--title = "Use these rules to filter photos based on their keywords when publishing.",
		title = "Use these rules remove keywords from photos in Piwigo when published. ",
		font = "<system>",
	}

	elements[#elements + 1] = f:static_text {
		title = "One rule per line. Wildcards: * matches any number of characters, ? matches exactly one character.",
		font = "<system>",
	}
	elements[#elements + 1] = f:static_text {
		title = "Examples: nature* (nature, natureza, etc.), *photo* (photograph, photoshop, etc.), ?at (bat, cat, hat, etc.)",
		font = "<system>",
	}
	if not options.showOverrideHint then
		elements[#elements + 1] = f:static_text {
			title = "Rules can also be set for individual albums, overriding these global settings.",
			font = "<system>",
		}
	end

	if options.showOverrideHint then
		elements[#elements + 1] = f:static_text {
			title = "Leave empty to use global settings from Publish Settings.",
			font = "<system>",
		}
	end

	elements[#elements + 1] = f:spacer { height = 2 }
	elements[#elements + 1] = f:row {
		fill_horizontal = 1,
		spacing = f:control_spacing(),
		f:column(exclusionColDef),
		f:column(inclusionColDef),
	}

	return elements
end

-- *************************************************
-- Create Keyword Filtering UI section (standalone group_box)
-- Returns a group_box with exclusion and inclusion rules
-- Used in PublishTask for collection settings dialogs
-- *************************************************
function UIHelpers.createKeywordFilteringUI(f, bind, collectionSettings)
	local fields = UIHelpers.createKeywordFilteringFields(f, bind, {
		showOverrideHint = true,
		widthInChars = 35,
		heightInLines = 6,
		fillColumns = true,
	})

	local columnContents = {
		spacing = f:control_spacing(),
		fill_horizontal = 1,
		f:separator { fill_horizontal = 1 },
	}
	for _, elem in ipairs(fields) do
		columnContents[#columnContents + 1] = elem
	end

	return f:group_box {
		title = "Keyword Filtering (Overrides defaults set in Publish Settings)",
		font = "<system/bold>",
		size = 'regular',
		fill_horizontal = 1,
		bind_to_object = assert(collectionSettings),
		f:column(columnContents),
	}
end

-- *************************************************
-- Create "Keyword Settings" group_box for PublishDialogSections
-- Combines checkboxes (Hierarchy/Synonyms) + filtering fields
-- Built dynamically to allow merging fixed elements with shared filtering fields
-- *************************************************
function UIHelpers.createKeywordSettingsGroupBox(f, bind)
	local filterFields = UIHelpers.createKeywordFilteringFields(f, bind, {
		showOverrideHint = false,
		widthInChars = 30,
		heightInLines = 8,
		fillColumns = false,
	})

	local groupBoxDef = {
		title = "Keyword Settings",
		font = "<system/bold>",
		fill_horizontal = 1,
		-- Checkboxes
		f:spacer { height = 2 },
		f:row {
			fill_horizontal = 1,
			f:static_text {
				title = "",
				alignment = 'right',
				width_in_chars = 7,
			},
			f:checkbox {
				font = "<system>",
				title = "Include Full Keyword Hierarchy",
				tooltip = "If checked, all keywords in a keyword hierarchy will be sent to Piwigo",
				value = bind 'KwFullHierarchy',
			},
		},
		f:spacer { height = 2 },
		f:row {
			fill_horizontal = 1,
			f:static_text {
				title = "",
				alignment = 'right',
				width_in_chars = 7,
			},
			f:checkbox {
				font = "<system>",
				title = "Include Keyword Synonyms",
				tooltip = "If checked, keyword synonyms will be sent to Piwigo",
				value = bind 'KwSynonyms',
			},
		},
		f:spacer { height = 2 },
		f:separator { fill_horizontal = 1 },
		f:spacer { height = 2 },
	}

	-- Append filtering fields dynamically
	for _, elem in ipairs(filterFields) do
		groupBoxDef[#groupBoxDef + 1] = elem
	end

	return f:group_box(groupBoxDef)
end

-- *************************************************
-- Create "Export Settings" group_box for PublishDialogSections
-- Combines checkboxes (Hierarchy/Synonyms) + filtering fields
-- Built dynamically to allow merging fixed elements with shared filtering fields
-- *************************************************
function UIHelpers.createExportSettingsGroupBox(f, bind, collectionSettings)
	local reSizeOptions = {
		{ title = "Long Edge",  value = "Long Edge" },
		{ title = "Short Edge", value = "Short Edge" },
		{ title = "Dimensions", value = "Dimensions" },
		{ title = "Megapixels", value = "MegaPixels" },
		{ title = "Percent",    value = "Percent" },
	}
	local metaDataOpts = {
		{ title = "All Metadata",                        value = "All Metadata" },
		{ title = "Copyright only",                      value = "Copyright Only" },
		{ title = "Copyright & Contact Info Only",       value = "Copyright & Contact Info Only" },
		{ title = "All Except Camera Raw Info",          value = "All Except Camera Raw Info" },
		{ title = "All Except Camera & Camera Raw Info", value = "All Except Camera & Camera Raw Info" },
	}

	local pubSettingsUI = f:group_box {
		title = "Custom Publish Settings (Overrides defaults set in Publish Settings)",
		font = "<system/bold>",
		size = 'regular',
		fill_horizontal = 1,
		bind_to_object = assert(collectionSettings),
		f:column {
			spacing = f:control_spacing(),
			fill_horizontal = 1,
			f:separator { fill_horizontal = 1 },
			f:row {
				f:checkbox {
					title = "Use custom settings for this album",
					tooltip = "If checked, these settings will replace the defaults set in Publish Settings",
					value = bind 'enableCustom',
				}
			},
			f:row {
				f:group_box { -- group for export parameters
					title = "Export Settings",
					visible = bind 'enableCustom',
					font = "<system>",
					fill_horizontal = 1,
					f:row {
						fill_horizontal = 1,
						spacing = f:label_spacing(),

						f:checkbox {
							title = "Resize Image",
							tooltip = "If checked, published image will be resized per these settings",
							value = bind 'reSize',
						},
						f:static_text {
							title = "Use :",
							alignment = 'right',
							fill_horizontal = 1,
						},

						f:popup_menu {
							value = bind 'reSizeParam',
							items = reSizeOptions,
							value_equal = valueEqual,
						},
						f:checkbox {
							title = "Allow Enlarge Image",
							tooltip = "If checked, published image will be enlarged if necessary",
							value = bind 'reSizeEnlarge',
						},

					},
				},
			},
		},
	}
end

-- *************************************************
return UIHelpers
