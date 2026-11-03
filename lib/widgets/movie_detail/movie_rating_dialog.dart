import 'package:flutter/material.dart';
import 'package:movielog/service/movie_rating_preference.dart';
import 'package:movielog/widgets/common/MovieRatingInput.dart';

class MovieRatingDialog extends StatefulWidget {
  const MovieRatingDialog({
    super.key,
    required this.movieId,
    this.ratingPreference,
  });

  final int movieId;
  final MovieRatingPreference? ratingPreference;

  @override
  State<MovieRatingDialog> createState() => _MovieRatingDialogState();
}

class _MovieRatingDialogState extends State<MovieRatingDialog> {
  double _rating = 0;
  late final MovieRatingPreference _ratingPreference;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ratingPreference = widget.ratingPreference ?? MovieRatingPreference();
    _loadRating();
  }

  Future<void> _loadRating() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final savedRating = await _ratingPreference.read(widget.movieId);
      if (!mounted) return;
      setState(() {
        _rating = savedRating ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _error = '저장된 평점을 불러오지 못했어요.';
      });
    }
  }

  Future<void> _saveRating() async {
    if (_isLoading || _isSaving || _loadFailed || _rating <= 0) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _ratingPreference.save(widget.movieId, _rating);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = '평점을 저장하지 못했어요. 다시 시도해 주세요.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, _rating);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: const Text('평점 남기기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (!_loadFailed) ...[
              AbsorbPointer(
                absorbing: _isSaving,
                child: MovieRatingInput(
                  rating: _rating,
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text('${_rating.toStringAsFixed(1)} / 5.0'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_loadFailed)
              TextButton(onPressed: _loadRating, child: const Text('다시 불러오기')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: !_isLoading && !_isSaving && !_loadFailed && _rating > 0
                ? _saveRating
                : null,
            child: Text(_isSaving ? '저장 중…' : '확인'),
          ),
        ],
      ),
    );
  }
}
