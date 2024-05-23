import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../domain/enums/library_layout_mode.dart';
import '../../../providers/library_tab_page_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/error_widget.dart';
import '../widgets/anime_tab_content.dart';
import '../widgets/loading_item.dart';
import '../widgets/empty_list.dart';

class OnHoldTab extends ConsumerWidget {
  const OnHoldTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onHoldTabPageProvider);

    final LibraryLayoutMode currentLayout = ref
        .watch(settingsProvider.select((settings) => settings.libraryLayout));

    return controller.animes.when(
      data: (data) {
        if (data.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(onHoldTabPageProvider),
            child: Stack(
              children: <Widget>[ListView(), const EmptyList()],
            ),
          );
        }

        return AnimeTabContent(
          data: data,
          currentLayout: currentLayout,
          onRefresh: () async => ref.refresh(onHoldTabPageProvider),
          pageStorageKey: const PageStorageKey<String>('OnHoldTab'),
        );
      },
      loading: () => LibraryLoadingItem(currentLayout),
      error: (err, stack) => CustomErrorWidget(
        err.toString(),
        () => ref.refresh(onHoldTabPageProvider),
      ),
    );
  }
}
