class Singleton {
public:
    Singleton()
    {
        ++_count;
    }

    int GetCount() const
    {
        return _count;
    }

private:
    int _count = 0;
};

// function included in multiple source files must be inline
// multiple definitions are permitted
// same address in every translation unit
inline Singleton& GetSingleton()
{
    static Singleton singleton;
    return singleton;
}
