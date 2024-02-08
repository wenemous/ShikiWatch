import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../../utils/extensions/date_time_ext.dart';
import '../../../widgets/auto_sliver_animated_list.dart';
import '../../../../utils/extensions/buildcontext.dart';
import '../../../widgets/flexible_sliver_app_bar.dart';
import '../../../../../kodik/models/kodik_anime.dart';
import '../../../widgets/error_widget.dart';
import '../../../../utils/app_utils.dart';
import '../../../../../kodik/kodik.dart';

import 'kodik_series_select_page.dart';
import 'anilibria_source_page.dart';
import 'latest_studio.dart';
import 'providers.dart';

enum KodikStudioType {
  all,
  voice,
  sub,
}

final kodikStudioTypeProvider = StateProvider<KodikStudioType>(
  (ref) => KodikStudioType.all,
  name: 'kodikStudioTypeProvider',
);

final sortedStudiosProvider = Provider.autoDispose
    .family<List<KodikStudio>, List<KodikStudio>>((ref, rawList) {
  final sortType = ref.watch(kodikStudioTypeProvider);

  switch (sortType) {
    case KodikStudioType.all:
      return rawList;
    case KodikStudioType.voice:
      return rawList.where((e) => e.type == 'voice').toList();
    case KodikStudioType.sub:
      return rawList.where((e) => e.type == 'subtitles').toList();
  }
}, name: 'sortedStudiosProvider');

class KodikSourcePage extends ConsumerWidget {
  final int shikimoriId;
  final int epWatched;
  final String animeName;
  final String searchName;
  final String imageUrl;
  final List<String> searchList;

  const KodikSourcePage({
    super.key,
    required this.shikimoriId,
    required this.epWatched,
    required this.animeName,
    required this.searchName,
    required this.imageUrl,
    required this.searchList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<KodikAnime> studios =
        ref.watch(kodikAnimeProvider(shikimoriId));
    final latestStudio = ref.watch(latestStudioProvider(shikimoriId));
    final studioType = ref.watch(kodikStudioTypeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(kodikAnimeProvider(shikimoriId).future),
        child: SafeArea(
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              FlexibleSliverAppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Text(
                  animeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    color: context.theme.colorScheme.onSurface,
                  ),
                ),
                bottomContent: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: [
                      const SizedBox(
                        width: 8.0,
                      ),
                      ChoiceChip(
                        label: const Text('Все'),
                        selected: studioType == KodikStudioType.all,
                        onSelected: (value) => ref
                            .read(kodikStudioTypeProvider.notifier)
                            .state = KodikStudioType.all,
                      ),
                      ChoiceChip(
                        label: const Text('Озвучка'),
                        selected: studioType == KodikStudioType.voice,
                        onSelected: (value) => ref
                            .read(kodikStudioTypeProvider.notifier)
                            .state = KodikStudioType.voice,
                      ),
                      ChoiceChip(
                        label: const Text('Субтитры'),
                        selected: studioType == KodikStudioType.sub,
                        onSelected: (value) => ref
                            .read(kodikStudioTypeProvider.notifier)
                            .state = KodikStudioType.sub,
                      ),
                      const SizedBox(
                        width: 8.0,
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    tooltip: '',
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem<int>(
                          value: 0,
                          child: Text("Искать в AniLibria"),
                        ),
                      ];
                    },
                    onSelected: (value) {
                      if (value == 0) {
                        //Navigator.pop(context);

                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation1, animation2) =>
                                AnilibriaSourcePage(
                              shikimoriId: shikimoriId,
                              animeName: animeName,
                              searchName: searchName,
                              epWatched: epWatched,
                              imageUrl: imageUrl,
                              searchList: searchList,
                            ),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SliverToBoxAdapter(
                child: Divider(
                  height: 1,
                ),
              ),
              ...studios.when(
                loading: () => [
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator())),
                ],
                error: (err, stack) => [
                  SliverFillRemaining(
                    child: CustomErrorWidget(err.toString(),
                        () => ref.refresh(kodikAnimeProvider(shikimoriId))),
                  ),
                ],
                data: (data) {
                  if (data.total == 0 || data.studio == null) {
                    return [const KodikNothingFound()];
                  }

                  final studioList =
                      ref.watch(sortedStudiosProvider(data.studio!));

                  if (studioList.isEmpty) {
                    return [const KodikNothingFound()];
                  }

                  return [
                    latestStudio.maybeWhen(
                      skipError: true,
                      data: (latestStudio) {
                        if (latestStudio == null) {
                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        }

                        return LatestStudio(
                          studio: latestStudio,
                          onContinue: () {
                            final element = data.studio!.firstWhereOrNull(
                                (e) => e.studioId == latestStudio.id);
                            if (element == null) {
                              showErrorSnackBar(
                                  ctx: context, msg: 'element == null');
                              return;
                            }

                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                settings: const RouteSettings(
                                  name: 'series select page',
                                ),
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        SeriesSelectPage(
                                  seriesList: element.kodikSeries,
                                  studioId: element.studioId ?? 0,
                                  shikimoriId: shikimoriId,
                                  episodeWatched: epWatched,
                                  animeName: animeName,
                                  studioName: element.name ?? '',
                                  studioType: element.type ?? '',
                                  imageUrl: imageUrl,
                                ),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            );
                          },
                        );
                      },
                      orElse: () {
                        return const SliverToBoxAdapter(
                            child: SizedBox.shrink());
                      },
                    ),

                    AutoAnimatedSliverList(
                      items: studioList,
                      itemBuilder: (context, _, index, animation) {
                        studioList.sort(
                          (a, b) {
                            final int sortByEpCount =
                                -a.episodesCount!.compareTo(b.episodesCount!);
                            if (sortByEpCount == 0) {
                              final int sortByUpdate =
                                  -a.updatedAt!.compareTo(b.updatedAt!);
                              return sortByUpdate;
                            }
                            return sortByEpCount;
                          },
                        );

                        final studio = studioList[index];

                        final updatedAtDateTime =
                            DateTime.parse(studio.updatedAt!).toLocal();

                        return SizeFadeTransition(
                          animation: animation,
                          child: StudioListTile(
                            name: studio.name ?? '',
                            type: studio.type ?? '',
                            update: updatedAtDateTime.convertToDaysAgo(),
                            episodeCount: studio.episodesCount ?? 0,
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                settings: const RouteSettings(
                                  name: 'series select page',
                                ),
                                pageBuilder:
                                    (context, animation1, animation2) =>
                                        SeriesSelectPage(
                                  seriesList: studio.kodikSeries,
                                  studioId: studio.studioId ?? 0,
                                  shikimoriId: shikimoriId,
                                  episodeWatched: epWatched,
                                  animeName: animeName,
                                  studioName: studio.name ?? '',
                                  studioType: studio.type ?? '',
                                  imageUrl: imageUrl,
                                ),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // SliverList.builder(
                    //   itemBuilder: (context, index) {
                    //     studioList.sort(
                    //       (a, b) {
                    //         final int sortByEpCount =
                    //             -a.episodesCount!.compareTo(b.episodesCount!);
                    //         if (sortByEpCount == 0) {
                    //           final int sortByUpdate =
                    //               -a.updatedAt!.compareTo(b.updatedAt!);
                    //           return sortByUpdate;
                    //         }
                    //         return sortByEpCount;
                    //       },
                    //     );

                    //     final studio = studioList[index];

                    //     final updatedAtDateTime =
                    //         DateTime.parse(studio.updatedAt!).toLocal();

                    //     return StudioListTile(
                    //       name: studio.name ?? '',
                    //       type: studio.type ?? '',
                    //       update: updatedAtDateTime.convertToDaysAgo(),
                    //       episodeCount: studio.episodesCount ?? 0,
                    //       onTap: () => Navigator.push(
                    //         context,
                    //         PageRouteBuilder(
                    //           settings: const RouteSettings(
                    //             name: 'series select page',
                    //           ),
                    //           pageBuilder: (context, animation1, animation2) =>
                    //               SeriesSelectPage(
                    //             seriesList: studio.kodikSeries,
                    //             studioId: studio.studioId ?? 0,
                    //             shikimoriId: shikimoriId,
                    //             episodeWatched: epWatched,
                    //             animeName: animeName,
                    //             studioName: studio.name ?? '',
                    //             studioType: studio.type ?? '',
                    //             imageUrl: imageUrl,
                    //           ),
                    //           transitionDuration: Duration.zero,
                    //           reverseTransitionDuration: Duration.zero,
                    //         ),
                    //       ),
                    //     );
                    //   },
                    //   itemCount: studioList.length,
                    // ),

                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudioListTile extends StatelessWidget {
  const StudioListTile({
    super.key,
    required this.name,
    required this.type,
    required this.update,
    required this.episodeCount,
    required this.onTap,
  });

  final String name;
  final String type;
  final String update;
  final int episodeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: studio.studioId == 610
      //     ? const Icon(Icons.push_pin_rounded)
      //     : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              name.replaceFirst('.Subtitles', ''),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          //if (studio.name!.contains('.Subtitles'))
          if (type == 'subtitles')
            const _CustomInfoChip(
              title: 'Субтитры',
            ),
        ],
      ),
      subtitle: Text(
        'Обновлено $update',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          color: context.colorScheme.onBackground.withOpacity(0.8),
        ),
      ),
      trailing: Text(
        '$episodeCount эп.',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          color: context.colorScheme.onBackground.withOpacity(0.8),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _CustomInfoChip extends StatelessWidget {
  final String title;

  const _CustomInfoChip({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      //margin: const EdgeInsets.all(0.0),
      margin: const EdgeInsets.only(left: 4, right: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
      color: context.theme.colorScheme.tertiaryContainer,
      //elevation: 0.0,
      child: Padding(
        //padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: context.theme.colorScheme.onTertiaryContainer,
          ),
        ),
      ),
    );
  }
}

class KodikNothingFound extends StatelessWidget {
  const KodikNothingFound({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Σ(ಠ_ಠ)',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.displayMedium,
                ),
              ),
              const Flexible(
                child: Text(
                  'Ничего не найдено',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
