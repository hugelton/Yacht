local gfx <const> = playdate.graphics

FileDialog = {}

FileDialog.isOpen = false
FileDialog.files = {}
FileDialog.selectedIndex = 1
FileDialog.scrollOffset = 0
FileDialog.maxVisibleItems = 7
FileDialog.itemHeight = 20
FileDialog.width = 360
FileDialog.height = 180
FileDialog.x = (400 - FileDialog.width) / 2
FileDialog.y = (240 - FileDialog.height) / 2
FileDialog.callback = nil
FileDialog.currentPath = ""
FileDialog.fileType = ""

function FileDialog.open(path, fileType, callback)
    cursor.hide()
    FileDialog.isOpen = true
    FileDialog.currentPath = path
    FileDialog.fileType = fileType
    FileDialog.callback = callback
    FileDialog.selectedIndex = 1
    FileDialog.scrollOffset = 0
    FileDialog:loadFiles()
    currentFocus = "FileDialog"
end

function FileDialog.close()
    cursor.show()
    FileDialog.isOpen = false
    currentFocus = "main" -- または前のフォーカス状態に戻す
end

function FileDialog:loadFiles()
    self.files = {}
    local allFiles = playdate.file.listFiles(self.currentPath)

    -- Add parent directory option if not at root
    if self.currentPath ~= "/" then
        table.insert(self.files, { name = "..", type = "parent" })
    end

    for _, file in ipairs(allFiles) do
        local fullPath = self.currentPath .. "/" .. file
        local fileType = playdate.file.getType(fullPath)
        if fileType == "folder" then
            table.insert(self.files, { name = file, type = "folder" })
        elseif self.fileType == "" or file:match("%." .. self.fileType .. "$") then
            -- .jsonファイルのみを表示
            if file:match("%.json$") then
                table.insert(self.files, { name = file, type = fileType })
            end
        end
    end
end

function FileDialog.handleInput()
    if not FileDialog.isOpen then return end

    if KeyManager.justReleased(KeyManager.keys.up) then
        FileDialog.selectedIndex = math.max(1, FileDialog.selectedIndex - 1)
        FileDialog:adjustScroll()
    elseif KeyManager.justReleased(KeyManager.keys.down) then
        FileDialog.selectedIndex = math.min(#FileDialog.files, FileDialog.selectedIndex + 1)
        FileDialog:adjustScroll()
    elseif CrankManager.forwardTick then
        FileDialog.selectedIndex = math.max(1, FileDialog.selectedIndex - 1)
        FileDialog:adjustScroll()
    elseif CrankManager.backwardTick then
        FileDialog.selectedIndex = math.min(#FileDialog.files, FileDialog.selectedIndex + 1)
        FileDialog:adjustScroll()
    elseif KeyManager.justReleased(KeyManager.keys.a) then
        local selectedFile = FileDialog.files[FileDialog.selectedIndex]
        if selectedFile.type == "folder" then
            FileDialog.currentPath = FileDialog.currentPath .. "/" .. selectedFile.name
            FileDialog:loadFiles()
            FileDialog.selectedIndex = 1
            FileDialog.scrollOffset = 0
        elseif selectedFile.type == "parent" then
            FileDialog.currentPath = FileDialog.currentPath:match("(.+)/[^/]*$") or "/"
            FileDialog:loadFiles()
            FileDialog.selectedIndex = 1
            FileDialog.scrollOffset = 0
        else
            local fullPath = FileDialog.currentPath .. "/" .. selectedFile.name
            FileDialog.close()
            if FileDialog.callback then
                FileDialog.callback(fullPath)
            end
        end
    elseif KeyManager.justReleased(KeyManager.keys.b) then
        FileDialog.close()
        if FileDialog.callback then
            FileDialog.callback(nil)
        end
    end
end

function FileDialog:adjustScroll()
    if self.selectedIndex <= self.scrollOffset then
        self.scrollOffset = self.selectedIndex - 1
    elseif self.selectedIndex > self.scrollOffset + self.maxVisibleItems then
        self.scrollOffset = self.selectedIndex - self.maxVisibleItems
    end
end

function FileDialog.getFileIcon(file)
    if file.type == "parent" or file.type == "folder" then
        return "📁"
    else
        local extension = file.name:match("%.([^%.]+)$") or ""
        extension = extension:lower()

        if extension == "txt" then
            return "T"
        elseif extension == "wav" or extension == "mp3" or extension == "ogg" then
            return "💽"
        elseif extension == "json" or extension == "yacht" then
            return "📄"
        else
            return "O"
        end
    end
end

FileDialog.mask = {}

FileDialog.mask.target = 1
FileDialog.mask.current = 0
FileDialog.mask.alpha = 0.7

function FileDialog.mask.draw()
    FileDialog.mask.current = FileDialog.mask.current +
        FileDialog.mask.alpha * (FileDialog.mask.target - FileDialog.mask.current)

    if FileDialog.isOpen then
        FileDialog.mask.target = 0.5
    else
        FileDialog.mask.target = 1
    end

    gfx.setColor(gfx.kColorWhite)
    gfx.setDitherPattern(FileDialog.mask.current)
    gfx.fillRect(0, 0, 400, 240)
end

function FileDialog.draw()
    FileDialog.mask.draw()
    if not FileDialog.isOpen then return end

    gfx.pushContext()

    -- Draw background
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(FileDialog.x, FileDialog.y, FileDialog.width, FileDialog.height, 0)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(FileDialog.x, FileDialog.y, FileDialog.width, FileDialog.height, 0)

    -- Draw title



    gfx.drawTextAligned("📁" .. "*" .. FileDialog.currentPath .. "*", FileDialog.x + FileDialog.width / 2,
        FileDialog.y + 10,
        kTextAlignment.center)
    gfx.drawRect(FileDialog.x + 10, FileDialog.y + 28, FileDialog.width - 30,
        FileDialog.itemHeight * FileDialog.maxVisibleItems + 1)



    gfx.drawRect(FileDialog.x + FileDialog.width - 21, FileDialog.y + 28, 17,
        FileDialog.itemHeight * FileDialog.maxVisibleItems + 1)
    -- Draw items
    for i = 1, math.min(FileDialog.maxVisibleItems, #FileDialog.files) do
        local index = i + FileDialog.scrollOffset
        local item = FileDialog.files[index]
        local y = FileDialog.y + 28 + (i - 1) * FileDialog.itemHeight



        -- grid



        gfx.setDitherPattern(0.5)
        gfx.drawRect(FileDialog.x + 10, y, FileDialog.width - 30, FileDialog.itemHeight + 1)
        gfx.setDitherPattern(0)





        -- select

        if index == FileDialog.selectedIndex then
            gfx.fillRect(FileDialog.x + 10, y, FileDialog.width - 30, FileDialog.itemHeight)
            gfx.setImageDrawMode(gfx.kDrawModeInverted)
        end

        local icon = FileDialog.getFileIcon(item)
        gfx.drawText(icon, FileDialog.x + 15, y + 6)

        assets.fonts.nada:drawText(item.name, FileDialog.x + 35, y + 6)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    -- Draw scrollbar if needed
    if #FileDialog.files > FileDialog.maxVisibleItems then
        local scrollBarHeight = (FileDialog.maxVisibleItems / #FileDialog.files) * (FileDialog.height - 80)
        local scrollBarY = FileDialog.y + 28 +
            (FileDialog.scrollOffset / (#FileDialog.files - FileDialog.maxVisibleItems)) *
            (FileDialog.height - 40 - scrollBarHeight)
        gfx.fillRoundRect(FileDialog.x + FileDialog.width - 19, scrollBarY, 13, scrollBarHeight, 2)
    end

    gfx.popContext()
end

return FileDialog
