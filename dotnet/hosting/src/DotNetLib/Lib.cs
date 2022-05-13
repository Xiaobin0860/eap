using System;
using System.Runtime.InteropServices;
using Helloworld;

namespace DotNetLib
{
    public static class Lib
    {
        private static int s_CallCount = 1;

        [StructLayout(LayoutKind.Sequential)]
        public struct LibArgs
        {
            public IntPtr Message;
            public int Number;
        }

        public static int Hello(IntPtr arg, int argLength)
        {
            if (argLength < System.Runtime.InteropServices.Marshal.SizeOf(typeof(LibArgs)))
            {
                return 1;
            }

            LibArgs libArgs = Marshal.PtrToStructure<LibArgs>(arg);
            Console.WriteLine($"Hello, world! from {nameof(Lib)} [count: {s_CallCount++}]");
            PrintLibArgs(libArgs);
            return 0;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct RpcArgs
        {
            public IntPtr Message;
        }
        public static int SayHello(IntPtr arg, int argLength)
        {
            if (argLength < System.Runtime.InteropServices.Marshal.SizeOf(typeof(RpcArgs)))
            {
                return 1;
            }

            var libArgs = Marshal.PtrToStructure<RpcArgs>(arg);
            string message = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? Marshal.PtrToStringUni(libArgs.Message)
                : Marshal.PtrToStringUTF8(libArgs.Message);
            var channel = new Grpc.Core.Channel("[::1]:50051", Grpc.Core.ChannelCredentials.Insecure);
            var client = new Greeter.GreeterClient(channel);
            var reply = client.SayHello(new HelloRequest{ Name = message});
            Console.WriteLine($"{reply.Message}");

            return 0;
        }

        public delegate void CustomEntryPointDelegate(LibArgs libArgs);
        public static void CustomEntryPoint(LibArgs libArgs)
        {
            Console.WriteLine($"Hello, world! from {nameof(CustomEntryPoint)} in {nameof(Lib)}");
            PrintLibArgs(libArgs);
        }

#if NET5_0
        [UnmanagedCallersOnly]
        public static void CustomEntryPointUnmanaged(LibArgs libArgs)
        {
            CustomEntryPoint(libArgs);
        }
#endif

        private static void PrintLibArgs(LibArgs libArgs)
        {
            string message = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? Marshal.PtrToStringUni(libArgs.Message)
                : Marshal.PtrToStringUTF8(libArgs.Message);

            Console.WriteLine($"-- message: {message}");
            Console.WriteLine($"-- number: {libArgs.Number}");
        }
    }
}
