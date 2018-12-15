import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

const APP_TITLE = 'Packliste';

class Item {
  final String name;
  bool checked;

  Item({this.name, this.checked = false});
}

class Category {
  final String name;
  final List<Item> _items = [];

  int get itemsCount {
    return _items.length;
  }

  Category({this.name});

  addItem(Item item) {
    this._items.add(item);
  }

  getItemByIndex(int index) {
    return this._items[index];
  }
}

class PackingList {
  final List<Category> _categories = [];

  int get categoryCount => _categories.length;

  Iterable<Category> get categories => _categories;

  Category getCategory(categoryName) {
    return this._categories.firstWhere((item) => item.name == categoryName,
        orElse: () {
      final category = new Category(name: categoryName);
      _categories.add(category);
      return category;
    });
  }

  static Future<PackingList> fromCSV() async {
    var contents = await rootBundle.loadString('assets/generell.csv');
    final parsed = const CsvToListConverter(eol: '\n').convert(contents);
    final list = PackingList();
    parsed.forEach((element) {
      final categoryName = element[1];
      final category = list.getCategory(categoryName);
      category.addItem(Item(name: element[0]));
    });
    return list;
  }
}

void main() => runApp(PackingListApp());

class PackingListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: APP_TITLE,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new PackingListWidget(),
    );
  }
}

typedef OnItemToggled = void Function(Item item);

class TabbedPackingList extends StatelessWidget {
  final PackingList data;

  final OnItemToggled onToggle;

  TabbedPackingList({this.data, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: data.categoryCount,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(APP_TITLE),
            bottom: TabBar(
              isScrollable: true,
              tabs: data.categories
                  .map((category) => Tab(text: category.name))
                  .toList(),
            ),
          ),
          body: TabBarView(
              children: data.categories
                  .map((category) =>
                      CategoryList(category: category, onToggle: onToggle))
                  .toList()),
        ));
  }
}

class PackingListWidget extends StatefulWidget {
  @override
  PackingListWidgetState createState() => PackingListWidgetState();
}

class PackingListWidgetState extends State<PackingListWidget> {
  PackingList data;

  @override
  Widget build(BuildContext context) {
    if (data != null) {
      return TabbedPackingList(data: data, onToggle: _onToggle);
    }
    return FutureBuilder<PackingList>(
        future: PackingList.fromCSV(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            this.data = snapshot.data;
            return TabbedPackingList(data: data, onToggle: _onToggle);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        });
  }

  void _onToggle(Item item) {
    setState(() {
      item.checked = !item.checked;
    });
  }
}

class CategoryList extends StatelessWidget {
  final Category category;
  final OnItemToggled onToggle;
  const CategoryList({
    Key key,
    this.onToggle,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: category.itemsCount,
      itemBuilder: (context, index) {
        final item = category.getItemByIndex(index);
        return ListTile(
          leading: Icon(
              item.checked ? Icons.check_box : Icons.check_box_outline_blank),
          title: Text(
            item.name,
            style: TextStyle(
                decoration: item.checked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none),
          ),
          onTap: () {
            onToggle(item);
          },
        );
      },
    );
  }
}
