import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movies_page.dart';
import 'package:movielog/service/genre_preference.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

class TestGenrePreference implements GenrePreference {
  @override
  Future<String> read() async => '전체';

  @override
  Future<void> save(String genre) async {}

  @override
  Future<void> clear() async {}
}

class TestMovieListViewModel extends MovieListViewModel {
  TestMovieListViewModel()
    : super(TmdbMovieService(Dio()), genrePreference: TestGenrePreference());

  int retries = 0;
  int? requestedGenreId;

  @override
  Future<void> loadInitial() async {
    retries++;
    status = MovieListLoadStatus.loading;
    notifyListeners();
  }

  @override
  Future<void> selectGenre(int? genreId) async {
    requestedGenreId = genreId;
    selectedGenreId = genreId;
    notifyListeners();
  }

  void show(MovieListLoadStatus nextStatus) {
    status = nextStatus;
    notifyListeners();
  }
}

void main() {
  late TestMovieListViewModel viewModel;

  setUp(() => viewModel = TestMovieListViewModel());
  tearDown(() => viewModel.dispose());

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MovieListViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: MoviesPage()),
      ),
    );
  }

  testWidgets(
    'updates loading, empty and API movie content from notifications',
    (tester) async {
      await mount(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      viewModel.show(MovieListLoadStatus.empty);
      await tester.pump();
      expect(find.text('영화가 없어요'), findsOneWidget);

      viewModel.genres = [const TmdbGenreDto(id: 28, name: '액션')];
      viewModel.movies = [
        const TmdbMovieDto(
          id: 100,
          title: 'API 영화',
          overview: '',
          posterPath: null,
          backdropPath: null,
          releaseDate: '2026-10-26',
          genreIds: [28],
          voteAverage: 8,
          popularity: 10,
        ),
      ];
      viewModel.show(MovieListLoadStatus.success);
      await tester.pump();
      expect(find.text('API 영화'), findsOneWidget);
      expect(find.text('2026 • 액션'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows error message and retries through the view model', (
    tester,
  ) async {
    viewModel.message = '요청 실패';
    viewModel.status = MovieListLoadStatus.error;
    await mount(tester);
    expect(find.text('요청 실패'), findsOneWidget);

    await tester.tap(find.text('다시 시도하기'));
    await tester.pump();
    expect(viewModel.retries, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'passes genre IDs and the all-genres selection to the view model',
    (tester) async {
      viewModel.genres = [const TmdbGenreDto(id: 28, name: '액션')];
      await mount(tester);

      await tester.tap(find.text('액션'));
      await tester.pump();
      expect(viewModel.requestedGenreId, 28);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '액션'))
            .selected,
        isTrue,
      );

      await tester.tap(find.text('전체'));
      await tester.pump();
      expect(viewModel.requestedGenreId, isNull);
    },
  );
}
