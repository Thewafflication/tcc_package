double _Complex destination;
struct incompatible {
    int member;
} source;

void assign_incompatible_type(void)
{
    destination = source;
}
