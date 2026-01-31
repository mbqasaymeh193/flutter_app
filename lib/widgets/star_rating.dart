class StarRating extends StatelessWidget {
  final double rating;
  final int count;

  const StarRating({super.key, required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < rating.round() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          );
        }),
        const SizedBox(width: 6),
        Text('($count)'),
      ],
    );
  }
}
