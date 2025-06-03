-- Object to handle pages

local pagination = {}
pagination.page = 1
pagination.page_size = 10
pagination.element_number = 0
pagination.refresh = function(self, element_number)
    self.element_number = element_number
    self.page = self:clamp_page(self.page)
end
pagination.get_index_range = function(self)
    local start_index = (self.page - 1) * self.page_size + 1
    local end_index = math.min(start_index + self.page_size - 1, self.element_number)
    
    return start_index, end_index
end
pagination.page_exists = function(self, page)
    return page > 0 and page <= math.ceil(self.element_number / self.page_size)
end
pagination.max_pages = function(self)
    return math.ceil(self.element_number / self.page_size)
end
pagination.change_page = function(self, amount)
    if self:page_exists(self.page + amount) then
        self.page = self.page + amount
    end
end
pagination.clamp_page = function(self, page)
    if (not page) or page < 1 then
        page = 1
    elseif page > self:max_pages() then
        page = self:max_pages()
    end
    return page
end

return pagination
