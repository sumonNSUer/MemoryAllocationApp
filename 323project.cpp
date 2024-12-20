#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

class MemoryBlock {
public:
    int start;
    int size;
    bool isFree;

    MemoryBlock(int start, int size) : start(start), size(size), isFree(true) {}

    int end() const { return start + size - 1; }
};

class Page {
public:
    int size;
    int allocatedStart;
    int allocatedEnd;

    Page(int size) : size(size), allocatedStart(-1), allocatedEnd(-1) {}
};

class BlockedRegion {
public:
    int start;
    int end;

    BlockedRegion(int start, int end) : start(start), end(end) {}
};

// Adjust available memory blocks by removing blocked regions
void adjustMemoryBlocks(std::vector<MemoryBlock>& blocks, const std::vector<BlockedRegion>& blockedRegions) {
    std::vector<MemoryBlock> adjustedBlocks;

    for (const auto& block : blocks) {
        int currentStart = block.start;
        int currentSize = block.size;

        for (const auto& region : blockedRegions) {
            if (region.start >= currentStart + currentSize || region.end <= currentStart) {
                continue; // No overlap
            }

            if (region.start > currentStart) {
                adjustedBlocks.push_back(MemoryBlock(currentStart, region.start - currentStart));
            }
            currentStart = std::max(currentStart, region.end);
            currentSize = block.size - (currentStart - block.start);
        }

        if (currentSize > 0) {
            adjustedBlocks.push_back(MemoryBlock(currentStart, currentSize));
        }
    }

    blocks = adjustedBlocks;
}

// Best-fit allocation
bool bestFit(std::vector<MemoryBlock>& blocks, Page& page) {
    auto bestBlock = blocks.end();
    for (auto it = blocks.begin(); it != blocks.end(); ++it) {
        if (it->isFree && it->size >= page.size) {
            if (bestBlock == blocks.end() || it->size < bestBlock->size) {
                bestBlock = it;
            }
        }
    }
    if (bestBlock != blocks.end()) {
        page.allocatedStart = bestBlock->start;
        page.allocatedEnd = bestBlock->start + page.size - 1;
        bestBlock->start += page.size;
        bestBlock->size -= page.size;
        if (bestBlock->size == 0) {
            bestBlock->isFree = false;
        }
        return true;
    }
    return false;
}

// First-fit allocation
bool firstFit(std::vector<MemoryBlock>& blocks, Page& page) {
    for (auto& block : blocks) {
        if (block.isFree && block.size >= page.size) {
            page.allocatedStart = block.start;
            page.allocatedEnd = block.start + page.size - 1;
            block.start += page.size;
            block.size -= page.size;
            if (block.size == 0) {
                block.isFree = false;
            }
            return true;
        }
    }
    return false;
}

// Worst-fit allocation
bool worstFit(std::vector<MemoryBlock>& blocks, Page& page) {
    auto worstBlock = blocks.end();
    for (auto it = blocks.begin(); it != blocks.end(); ++it) {
        if (it->isFree && it->size >= page.size) {
            if (worstBlock == blocks.end() || it->size > worstBlock->size) {
                worstBlock = it;
            }
        }
    }
    if (worstBlock != blocks.end()) {
        page.allocatedStart = worstBlock->start;
        page.allocatedEnd = worstBlock->start + page.size - 1;
        worstBlock->start += page.size;
        worstBlock->size -= page.size;
        if (worstBlock->size == 0) {
            worstBlock->isFree = false;
        }
        return true;
    }
    return false;
}

// Memory allocation based on strategy
void allocateMemory(std::vector<MemoryBlock>& blocks, std::vector<Page>& pages, const std::string& strategy) {
    bool (*allocationFunction)(std::vector<MemoryBlock>&, Page&);

    if (strategy == "first") {
        allocationFunction = firstFit;
    } else if (strategy == "best") {
        allocationFunction = bestFit;
    } else if (strategy == "worst") {
        allocationFunction = worstFit;
    } else {
        std::cerr << "Invalid strategy selected." << std::endl;
        return;
    }

    for (auto& page : pages) {
        if (!allocationFunction(blocks, page)) {
            std::cout << "Page of size " << page.size << " could not be allocated." << std::endl;
        }
    }

    // Display memory allocation results
    for (const auto& page : pages) {
        if (page.allocatedStart != -1) {
            std::cout << "Page of size " << page.size << " allocated from " << page.allocatedStart << " to " << page.allocatedEnd << "." << std::endl;
        } else {
            std::cout << "Page of size " << page.size << " could not be allocated." << std::endl;
        }
    }

    // Display remaining free memory blocks
    for (const auto& block : blocks) {
        if (block.isFree) {
            std::cout << "Free block from " << block.start << " to " << block.end() << " with size " << block.size << "." << std::endl;
        }
    }
}

int main() {
    int totalMemorySize;
    std::cout << "Enter total memory size: ";
    std::cin >> totalMemorySize;

    // Start with one free memory block of the entire memory size
    std::vector<MemoryBlock> blocks = { MemoryBlock(0, totalMemorySize) };

    int blockedCount;
    std::cout << "Enter number of blocked regions: ";
    std::cin >> blockedCount;

    std::vector<BlockedRegion> blockedRegions;
    for (int i = 0; i < blockedCount; i++) {
        int start, end;
        std::cout << "Enter start and end of blocked region " << i + 1 << ": ";
        std::cin >> start >> end;
        blockedRegions.push_back(BlockedRegion(start, end));
    }

    // Adjust available memory blocks by removing blocked regions
    adjustMemoryBlocks(blocks, blockedRegions);

    int totalPages;
    std::cout << "Enter the number of pages: ";
    std::cin >> totalPages;

    std::vector<Page> pages;
    for (int i = 0; i < totalPages; i++) {
        int pageSize;
        std::cout << "Enter size of page " << i + 1 << ": ";
        std::cin >> pageSize;
        pages.push_back(Page(pageSize));
    }

    std::string strategy;
    std::cout << "Choose allocation strategy (first/best/worst): ";
    std::cin >> strategy;

    allocateMemory(blocks, pages, strategy);

    return 0;
}
