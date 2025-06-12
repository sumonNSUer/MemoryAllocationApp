import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: MemoryAllocatorApp(),
  ));
}

class MemoryAllocatorApp extends StatefulWidget { //dynamic changing purpose
  const MemoryAllocatorApp({super.key});


  @override
  _MemoryAllocatorAppState createState() => _MemoryAllocatorAppState();
}

class _MemoryAllocatorAppState extends State<MemoryAllocatorApp> { // handles the dynamic behaviour
  final TextEditingController memorySizeController = TextEditingController();
  final List<TextEditingController> blockedRegionsControllers = [];
  final List<TextEditingController> pageSizesControllers = [];
  String selectedStrategy = 'best';
  List<String> strategies = ['first', 'best', 'worst'];

  List<Map<String, dynamic>> allocations = [];
  List<Map<String, int>> freeBlocks = [];

  @override
  Widget build(BuildContext context) { // to create ui
    return Scaffold(
        appBar: AppBar(
          title: const Text('Memory Allocator'),
        ),
        body: SingleChildScrollView(
            child: TextField(
                controller: memorySizeController
                child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [r,
              decoration: const InputDecoration(labelText: 'Enter total memory size'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addBlockedRegionFields,
              child: const Text('Add Blocked Region'),
            ),
            ...buildBlockedRegionFields(),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: addPageSizeFields,
          child: const Text('Add Page Size'),
        ),
        ...buildPageSizeFields(),
    const SizedBox(height: 10),
    DropdownButton<String>(
    value: selectedStrategy,
    onChanged: (String? newValue) {
    setState(() {
    selectedStrategy = newValue!;
    });
    },
    items: strategies.map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
    value: value,
    child: Text(value),
    );
    }).toList(),
    ),
    const SizedBox(height: 20),
    ElevatedButton(
    onPressed: calculateAllocation,
    child: const Text('Calculate Allocation'),
    ),
    const SizedBox(height: 20),
    const Text(
    'Allocation Results:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    ListView.builder( //Displays the results of memory allocations.
    shrinkWrap: true,
    itemCount: allocations.length,
    itemBuilder: (context, index) {
    final allocation = allocations[index];
    return Text(
    'Page of size ${allocation["size"]} allocated from ${allocation["start"]} to ${allocation["end"]}');
    },
    ),
    const SizedBox(height: 10),
    const Text(
    'Free Memory Blocks:',
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    ListView.builder(
    shrinkWrap: true,
    itemCount: freeBlocks.length,
    itemBuilder: (context, index) {
    final block = freeBlocks[index];
    return Text(
    'Free block from ${block["start"]} to ${block["end"]} with size ${block["size"]}');
    },
    ),
    ],
    ),
    ),
    ),
    );
  }

  void addBlockedRegionFields() {  //Adds two new input fields (start and end) for blocked regions.
    setState(() {
      blockedRegionsControllers.add(TextEditingController());
      blockedRegionsControllers.add(TextEditingController());
    });
  }

  List<Widget> buildBlockedRegionFields() { //Creates input fields for each blocked region's start and end.
    List<Widget> fields = [];
    for (int i = 0; i < blockedRegionsControllers.length; i += 2) {
      fields.add(Row(
        children: [
          Expanded(
            child: TextField(
              controller: blockedRegionsControllers[i],
              decoration: const InputDecoration(labelText: 'Start of blocked region'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: blockedRegionsControllers[i + 1],
              decoration: const InputDecoration(labelText: 'End of blocked region'),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ));
    }
    return fields;
  }

  void addPageSizeFields() {
    setState(() {
      pageSizesControllers.add(TextEditingController());
    });
  }

  List<Widget> buildPageSizeFields() {
    return pageSizesControllers.map((controller) {
      return TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Page Size'),
        keyboardType: TextInputType.number,
      );
    }).toList();
  }

  void calculateAllocation() {
    int memorySize = int.tryParse(memorySizeController.text) ?? 0;
    List<Map<String, int>> blockedRegions = [];
    for (int i = 0; i < blockedRegionsControllers.length; i += 2) {
      int start = int.tryParse(blockedRegionsControllers[i].text) ?? 0;
      int end = int.tryParse(blockedRegionsControllers[i + 1].text) ?? 0;
      blockedRegions.add({'start': start, 'end': end});
    }
    List<int> pageSizes = pageSizesControllers
        .map((controller) => int.tryParse(controller.text) ?? 0)
        .toList();

    allocations.clear();
    freeBlocks.clear();

    List<Map<String, int>> freeSpaces = [
      {'start': 0, 'end': memorySize - 1}
    ];

    // Remove blocked regions
    for (var block in blockedRegions) {
      freeSpaces = splitFreeSpaces(freeSpaces, block['start']!, block['end']!);
    }

    // Allocate pages based on the selected strategy
    for (int pageSize in pageSizes) {
      switch (selectedStrategy) {
        case 'first':
          firstFitAllocation(freeSpaces, pageSize);
          break;
        case 'best':
          bestFitAllocation(freeSpaces, pageSize);
          break;
        case 'worst':
          worstFitAllocation(freeSpaces, pageSize);
          break;
      }
    }

    // Collect remaining free spaces
    for (var space in freeSpaces) {
      int freeSize = (space['end'] ?? 0) - (space['start'] ?? 0) + 1;
      if (freeSize > 0) {
        freeBlocks.add({
          'start': space['start']!,
          'end': space['end']!,
          'size': freeSize,
        });
      }
    }

    setState(() {});
  }

  void firstFitAllocation(List<Map<String, int>> freeSpaces, int pageSize) {
    for (var space in freeSpaces) {
      int freeSize = (space['end'] ?? 0) - (space['start'] ?? 0) + 1;
      if (freeSize >= pageSize) {
        allocations.add({
          'size': pageSize,
          'start': space['start'],
          'end': space['start']! + pageSize - 1,
        });
        space['start'] = space['start']! + pageSize;
        return;
      }
    }
    print('Page of size $pageSize could not be allocated (First Fit)');
  }

  void bestFitAllocation(List<Map<String, int>> freeSpaces, int pageSize) {
    Map<String, int>? bestSpace;
    int minWaste = double.maxFinite.toInt();

    for (var space in freeSpaces) {
      int freeSize = (space['end'] ?? 0) - (space['start'] ?? 0) + 1;
      if (freeSize >= pageSize && (freeSize - pageSize) < minWaste) {
        bestSpace = space;
        minWaste = freeSize - pageSize;
      }
    }

    if (bestSpace != null) {
      allocations.add({
        'size': pageSize,
        'start': bestSpace['start'],
        'end': bestSpace['start']! + pageSize - 1,
      });
      bestSpace['start'] = bestSpace['start']! + pageSize;
    } else {
      print('Page of size $pageSize could not be allocated (Best Fit)');
    }
  }

  void worstFitAllocation(List<Map<String, int>> freeSpaces, int pageSize) {
    Map<String, int>? worstSpace;
    int maxWaste = -1;

    for (var space in freeSpaces) {
      int freeSize = (space['end'] ?? 0) - (space['start'] ?? 0) + 1;
      if (freeSize >= pageSize && (freeSize - pageSize) > maxWaste) {
        worstSpace = space;
        maxWaste = freeSize - pageSize;
      }
    }

    if (worstSpace != null) {
      allocations.add({
        'size': pageSize,
        'start': worstSpace['start'],
        'end': worstSpace['start']! + pageSize - 1,
      });
      worstSpace['start'] = worstSpace['start']! + pageSize;
    } else {
      print('Page of size $pageSize could not be allocated (Worst Fit)');
    }
  }


  List<Map<String, int>> splitFreeSpaces(
      List<Map<String, int>> spaces, int blockStart, int blockEnd) {
    List<Map<String, int>> updatedSpaces = [];
    for (var space in spaces) {
      if (blockEnd < (space['start'] ?? 0) || blockStart > (space['end'] ?? 0)) {
        updatedSpaces.add(space);
      } else {
        if (blockStart > (space['start'] ?? 0)) {
          updatedSpaces.add({'start': space['start']!, 'end': blockStart - 1});
        }
        if (blockEnd < (space['end'] ?? 0)) {
          updatedSpaces.add({'start': blockEnd + 1, 'end': space['end']!});
        }
      }
    }
    return updatedSpaces;
  }
}
